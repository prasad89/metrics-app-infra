#!/bin/bash

# This script is used to test the /counter endpoint of the web server
for i in $(seq 0 20); do
    time curl localhost/counter
done
