# TempConv

A simple temperature conversion app: **Celsius ↔ Fahrenheit**.  
**gRPC** backend (Go) with **Protocol Buffers**, Flutter web frontend via **gRPC-Web**, containerized and deployable on **Google Kubernetes Engine (GKE)** with AMD64 nodes.

- **Backend:** Go gRPC server, two RPCs returning only the converted value.
- **API:** Defined in `proto/tempconv/v1/tempconv.proto` (Protocol Buffers).
- **Frontend:** Flutter (Dart), gRPC-Web client; web build served by nginx.
- **gRPC-Web proxy:** Envoy translates browser gRPC-Web → backend gRPC.
- **Containers:** Docker (linux/amd64) for GKE.
- **Load tested:** Go gRPC client in `backend/cmd/loadtest`.

---

## Project layout

```
TempConv/
├── proto/
│   └── tempconv/v1/
│       └── tempconv.proto      # Service + Value message
├── backend/                    # Go gRPC server
│   ├── main.go
│   ├── internal/pb/            # Generated Go from proto
│   ├── cmd/loadtest/           # gRPC load test
│   ├── go.mod
│   └── Dockerfile
├── frontend/                   # Flutter web (gRPC-Web client)
│   ├── lib/main.dart
│   ├── lib/generated/          # Generated Dart from proto
│   ├── pubspec.yaml
│   └── Dockerfile
├── envoy/                      # gRPC-Web proxy
│   ├── envoy.yaml
│   └── Dockerfile
├── k8s/                        # Kubernetes manifests for GKE
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── envoy-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml
├── loadtest/
│   └── README.md               # Load test instructions
├── scripts/
│   └── gen.sh                  # Regenerate Go + Dart from proto
└── README.md
```

---

## Step-by-step guide

### 1. Prerequisites

- **Go** 1.21+ ([go.dev](https://go.dev/dl/))
- **Flutter** (for web) ([flutter.dev](https://flutter.dev))
- **Docker** (build images for linux/amd64)
- **kubectl** ([install](https://kubernetes.io/docs/tasks/tools/))
- **Google Cloud SDK** (`gcloud`) and a GCP project with Kubernetes Engine API enabled
- **protoc** (optional; only to regenerate code from proto; pre-generated code is committed)

### 2. Develop and test locally

**Backend (gRPC)**

```bash
cd backend
go build .
go test .
./backend   # or: go run .
# gRPC on :8080, HTTP health on :8081
```

**Test with grpcurl (optional):**

```bash
grpcurl -plaintext -d '{"value": 25}' localhost:8080 tempconv.v1.TempConv/CelsiusToFahrenheit
# {"value": 77}
```

**Frontend (gRPC-Web)**

For local dev, the Flutter app calls the same origin. You need Envoy (or another gRPC-Web proxy) in front of the backend so the browser can speak gRPC-Web. Options:

- Run Envoy locally pointing at the backend, and serve the Flutter app from a host that routes `/tempconv.v1.TempConv` to Envoy (e.g. same port with a reverse proxy).
- Or run the full stack in Docker/K8s and open the Ingress URL.

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

**Regenerate proto code (if you edit the .proto):**

```bash
# Go: need protoc-gen-go and protoc-gen-go-grpc on PATH
# Dart: dart pub global activate protoc_plugin; add $HOME/.pub-cache/bin to PATH
./scripts/gen.sh
```

### 3. Build Docker images (AMD64 for GKE)

From the **project root**:

```bash
docker build --platform linux/amd64 -t tempconv-backend:latest ./backend
docker build --platform linux/amd64 -t tempconv-envoy:latest ./envoy
docker build --platform linux/amd64 -t tempconv-frontend:latest ./frontend
```

### 4. Push images to a registry

**Google Artifact Registry (recommended):**

```bash
gcloud artifacts repositories create tempconv --repository-format=docker --location=REGION
gcloud auth configure-docker REGION-docker.pkg.dev

export PROJECT_ID=your-gcp-project-id
export REGION=your-region
docker tag tempconv-backend:latest REGION-docker.pkg.dev/$PROJECT_ID/tempconv/backend:latest
docker tag tempconv-envoy:latest REGION-docker.pkg.dev/$PROJECT_ID/tempconv/envoy:latest
docker tag tempconv-frontend:latest REGION-docker.pkg.dev/$PROJECT_ID/tempconv/frontend:latest
docker push REGION-docker.pkg.dev/$PROJECT_ID/tempconv/backend:latest
docker push REGION-docker.pkg.dev/$PROJECT_ID/tempconv/envoy:latest
docker push REGION-docker.pkg.dev/$PROJECT_ID/tempconv/frontend:latest
```

Update `image` in `k8s/*.yaml` to your registry URLs.

### 5. Create a GKE cluster (AMD64)

```bash
export PROJECT_ID=your-gcp-project-id
export REGION=your-region
export CLUSTER_NAME=tempconv-cluster

gcloud container clusters create $CLUSTER_NAME \
  --project=$PROJECT_ID --region=$REGION \
  --machine-type=e2-small --num-nodes=2 \
  --node-locations=$REGION-b

gcloud container clusters get-credentials $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID
```

### 6. Deploy to Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/envoy-deployment.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

Traffic flow:

- **Browser** → Ingress → `/tempconv.v1.TempConv` → **Envoy** (gRPC-Web) → **Backend** (gRPC)
- **Browser** → Ingress → `/` → **Frontend** (nginx)

Wait for the Ingress to get an external IP:

```bash
kubectl -n tempconv get ingress
```

### 7. Use the app

Open `http://<INGRESS_IP>` in a browser. The Flutter app uses gRPC-Web to call the same host; the Ingress routes `/tempconv.v1.TempConv` to Envoy, which forwards to the backend.

### 8. Load test (gRPC)

```bash
kubectl port-forward -n tempconv svc/tempconv-backend 8080:8080
cd backend && go run ./cmd/loadtest -target localhost:8080 -c 50 -d 1m
```

See `loadtest/README.md` for options.

---

## API (gRPC / Protocol Buffers)

**Proto:** `proto/tempconv/v1/tempconv.proto`

- **Message:** `Value { double value = 1; }`
- **Service:** `TempConv`
  - `CelsiusToFahrenheit(Value) returns (Value)`
  - `FahrenheitToCelsius(Value) returns (Value)`

Health: HTTP `GET http://<pod>:8081/health` → 200 OK (used by K8s probes).

---

## GKE and AMD64

- All Dockerfiles build for `linux/amd64`. GKE default nodes are AMD64.
- Manifests use `nodeSelector: kubernetes.io/arch: amd64`.
- On ARM (e.g. Mac M1), use `docker build --platform linux/amd64`.

---

## Cleanup

```bash
kubectl delete namespace tempconv
gcloud container clusters delete $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID
```

---

## License

MIT or as you prefer.
