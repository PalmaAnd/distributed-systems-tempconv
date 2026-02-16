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

For local dev, the Flutter app calls the same origin by default.  
With `flutter run -d web-server`, same-origin points to the Flutter dev server port (for example `http://localhost:41517`), so gRPC POSTs like `/tempconv.v1.TempConv/CelsiusToFahrenheit` return **404** unless you route that path elsewhere.

You need a gRPC-Web endpoint (Envoy or another gRPC-Web proxy) in front of the backend because the backend on `:8080` is plain gRPC (not gRPC-Web).

Set an explicit gRPC-Web endpoint:

- `--dart-define=GRPC_WEB_ENDPOINT=http://localhost:8081` (replace with your proxy URL)
- Or run the full stack in Docker/K8s and open the Ingress URL.

```bash
cd frontend
flutter pub get
flutter run -d web-server --dart-define=GRPC_WEB_ENDPOINT=http://localhost:8081
```

**Regenerate proto code (if you edit the .proto):**

```bash
# Go: need protoc-gen-go and protoc-gen-go-grpc on PATH
# Dart: dart pub global activate protoc_plugin; add $HOME/.pub-cache/bin to PATH
./scripts/gen.sh
```

### 3. Build and push Docker images (AMD64 for GKE)

Use the root `Makefile` targets:

```bash
make docker-release \
  PROJECT_ID=your-gcp-project-id \
  REGION=us-central1 \
  AR_REPO=tempconv \
  IMAGE_TAG=latest
```

What this does:

- creates Artifact Registry repo if missing
- runs `gcloud auth configure-docker`
- builds backend and frontend images for `linux/amd64`
- pushes both images to:
  - `REGION-docker.pkg.dev/PROJECT_ID/AR_REPO/tempconv-backend:IMAGE_TAG`
  - `REGION-docker.pkg.dev/PROJECT_ID/AR_REPO/tempconv-frontend:IMAGE_TAG`

`FRONTEND_BACKEND_URL` can be set at build time. Default is empty (`""`) so the web app calls `/v1/*` on the same host.

### 4. Create/connect GKE cluster (AMD64)

```bash
make gke-create \
  PROJECT_ID=your-gcp-project-id \
  REGION=us-central1 \
  CLUSTER_NAME=tempconv-cluster

make gke-creds \
  PROJECT_ID=your-gcp-project-id \
  REGION=us-central1 \
  CLUSTER_NAME=tempconv-cluster
```

### 5. Deploy to Kubernetes

```bash
make gke-deploy \
  PROJECT_ID=your-gcp-project-id \
  REGION=us-central1 \
  AR_REPO=tempconv \
  IMAGE_TAG=latest
```

This applies Kubernetes manifests and updates deployment images to the pushed Artifact Registry tags.

### 6. Use the app

For the current `k8s/ingress.yaml` (LoadBalancer services), get the frontend external IP:

```bash
kubectl -n tempconv get svc tempconv-frontend-lb
```

Open `http://<EXTERNAL_IP>` in a browser.

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
