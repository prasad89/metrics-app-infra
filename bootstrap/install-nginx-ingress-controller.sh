#!/bin/bash

# This script installs nginx ingress controller in the nginx namespace and waits for the controller deployment to be available.

# Create the ingress-nginx namespace to install nginx ingress controller
kubectl create namespace ingress-nginx

# Install NGINX ingress controller in the nginx namespace
kubectl apply -n ingress-nginx -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/main/deploy/static/provider/kind/deploy.yaml

echo "Waiting for NGINX ingress controller to be available..."
kubectl wait --for=condition=Available \
    --namespace ingress-nginx \
    --timeout=180s \
    deployment/ingress-nginx-controller
echo "NGINX ingress controller is available."
