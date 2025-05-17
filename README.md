# metrics-app-infra

GitOps-based deployment of a containerized app using SRE best practices with Helm, ArgoCD, and KIND.

## Quickstart

Use the provided Makefile to set up and deploy the environment:

```bash
# Create local Kubernetes cluster with KIND
make kind

# Install ArgoCD
make install_argocd

# Install NGINX Ingress Controller
make install_ingress_controller

# Deploy the metrics app via ArgoCD
make deploy

# Run tests
make test
```

## Cleanup

To delete the KIND cluster:

```bash
make clean
```

## Debugging

For troubleshooting steps and root cause analysis, see the [docs/Debugging.md](docs/Debugging.md).
