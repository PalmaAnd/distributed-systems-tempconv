# TempConv

A temperature converter app (Celsius ↔ Fahrenheit) built with **gRPC**, **Protocol Buffers**, **Go** backend, and **Flutter** web frontend. 
Built for containerization and deployment on **Google Kubernetes Engine (GKE)** with AMD64 nodes, for the course 'Distributed Systems'.


## Architecture

```
┌─────────────────┐     HTTP/JSON      ┌──────────────────┐
│  Flutter Web    │ ─────────────────► │   Go Backend     │
│  (Frontend)     │   /v1/c2f, /v1/f2c │   :8080 (REST)   │
└─────────────────┘                    │   :50051 (gRPC)  │
                                       └──────────────────┘
```

- **Backend**: Go gRPC server on port 50051 + HTTP REST gateway on port 8080
- **Frontend**: Flutter web app, calls backend via REST (browser-compatible)
- **API**: Two gRPC methods — `CelsiusToFahrenheit` (c2f) and `FahrenheitToCelsius` (f2c)

## Prerequisites

- **Go** 1.21+
- **Flutter** (for web)
- **Docker** (for images)
- **kubectl** + **gcloud** (for GKE)
- **k6** (for load testing)
- **protoc** + `protoc-gen-go`, `protoc-gen-go-grpc` (for proto regeneration)

## Project Structure

```
.
├── api/
│   └── tempconv.proto       # gRPC + Protobuf definitions
├── backend/
│   ├── cmd/server/          # Go gRPC + HTTP server
│   └── Dockerfile
├── frontend/
│   ├── lib/main.dart        # Flutter web UI
│   └── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   └── ingress.yaml
├── loadtest/
│   ├── loadtest.js           # k6 gRPC load test
│   └── tempconv.proto
├── Makefile
└── README.md
```
