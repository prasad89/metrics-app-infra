#!/bin/bash

# This script installs ArgoCD in the argocd namespace and waits for the argocd-server deployment to be available.

# Create the argocd namespace to install ArgoCD
kubectl create namespace argocd

# Install ArgoCD in the argocd namespace
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deploy/argocd-server -n argocd --timeout=180s
echo "ArgoCD server is available."

# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8081:443 &
