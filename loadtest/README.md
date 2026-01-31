# TempConv Load Tests

The backend uses **gRPC**. Load test it with the Go gRPC client (simulates many frontends calling the backend).

## gRPC load test (Go)

From the **backend** directory:

```bash
cd backend
# Backend must be running (go run . or container)
go run ./cmd/loadtest
# Options:
go run ./cmd/loadtest -target localhost:8080 -c 20 -d 30s
```

Against GKE (port-forward the gRPC backend first):

```bash
kubectl port-forward -n tempconv svc/tempconv-backend 8080:8080
cd backend && go run ./cmd/loadtest -target localhost:8080 -c 50 -d 1m
```

Flags:

- `-target`: gRPC server address (default `localhost:8080`)
- `-c`: concurrent goroutines (default 20)
- `-d`: test duration (default 30s)

## Regenerating proto code

After editing `proto/tempconv/v1/tempconv.proto`:

**Go (backend):**

```bash
# Install plugins: go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
#                 go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
./scripts/gen.sh
# Or manually:
protoc -I proto --go_out=backend/internal/pb --go_opt=paths=source_relative \
  --go-grpc_out=backend/internal/pb --go-grpc_opt=paths=source_relative \
  proto/tempconv/v1/tempconv.proto
```

**Dart (frontend):**

```bash
# dart pub global activate protoc_plugin
# export PATH="$PATH:$HOME/.pub-cache/bin"
protoc -I proto --dart_out=grpc:frontend/lib/generated proto/tempconv/v1/tempconv.proto
```
