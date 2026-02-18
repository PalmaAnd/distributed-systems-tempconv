# Project Guide

This guide covers containerization and deployment to Google Kubernetes Engine (GKE).

## 1) Build and Push Backend Image (AMD64)

From repo root:

```bash
docker build --platform linux/amd64 -t tempconv-backend:latest -f backend/Dockerfile .
```

Tag and push to Artifact Registry:

```bash
# Set your project and region
PROJECT_ID=your-gcp-project
REGION=us-central1

# Create repo once
gcloud artifacts repositories create tempconv \
  --repository-format=docker \
  --location=$REGION

# Configure auth
gcloud auth configure-docker $REGION-docker.pkg.dev

# Tag backend image
BACKEND_IMAGE=$REGION-docker.pkg.dev/$PROJECT_ID/tempconv/tempconv-backend:latest

docker tag tempconv-backend:latest $BACKEND_IMAGE

# Push
docker push $BACKEND_IMAGE
```

## 2) Create GKE Cluster

```bash
gcloud container clusters create tempconv-cluster \
  --zone us-central1-a \
  --num-nodes 2 \
  --machine-type e2-standard-2

gcloud container clusters get-credentials tempconv-cluster --zone us-central1-a
```

## 3) Deploy Backend and Get Backend IP
Apply:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

Check external IPs:

```bash
kubectl get svc -n tempconv
```

Copy the backend LoadBalancer IP (service `tempconv-backend-lb`).
You will need this IP for the frontend build in the next step.

## 4) Build and Push Frontend Image (with backend IP)

```bash
# Use backend HTTP LoadBalancer IP (service tempconv-backend-lb).
# Do NOT use gRPC port 50051 here.
BACKEND_IP=http://YOUR_BACKEND_LB_IP

docker build --platform linux/amd64 \
  --build-arg GRPC_BACKEND_URL=$BACKEND_IP \
  -t tempconv-frontend:latest -f frontend/Dockerfile frontend
```

If you pass only an IP/host without scheme, the frontend now normalizes it to
`http://<host>` automatically.

Tag and push:

```bash
FRONTEND_IMAGE=$REGION-docker.pkg.dev/$PROJECT_ID/tempconv/tempconv-frontend:latest

docker tag tempconv-frontend:latest $FRONTEND_IMAGE

docker push $FRONTEND_IMAGE
```

## 5) Deploy Frontend

Apply:

```bash
kubectl apply -f k8s/frontend-deployment.yaml
```

Get the frontend external IP:

```bash
kubectl get svc -n tempconv
```

Open the frontend with `http://YOUR_FRONTEND_LB_IP` (service `tempconv-frontend-lb`).

## 6) Verify

```bash
curl -s -X POST http://BACKEND_IP/v1/c2f \
  -H 'Content-Type: application/json' \
  -d '{"value": 0}'
```

## 7) Load Testing (k6)

```bash
# Local backend
BACKEND_URL=localhost:50051 k6 run loadtest/loadtest.js

# Remote backend (port-forward gRPC)
kubectl port-forward -n tempconv svc/tempconv-backend 50051:50051
BACKEND_URL=localhost:50051 k6 run loadtest/loadtest.js
```
