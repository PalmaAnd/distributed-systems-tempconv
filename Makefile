# TempConv - Build and deployment automation
.PHONY: proto backend frontend docker-build docker-build-gke docker-push docker-release \
	ar-auth ar-create check-project check-gcloud gke-creds gke-create gke-apply gke-deploy \
	loadtest test clean

# Default target
all: proto backend frontend

# --- Deployment config (override on command line) ---
PROJECT_ID ?=
REGION ?= us-central1
AR_REPO ?= tempconv
IMAGE_TAG ?= latest
CLUSTER_NAME ?= tempconv-cluster
FRONTEND_BACKEND_URL ?=

BACKEND_IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(AR_REPO)/tempconv-backend:$(IMAGE_TAG)
FRONTEND_IMAGE := $(REGION)-docker.pkg.dev/$(PROJECT_ID)/$(AR_REPO)/tempconv-frontend:$(IMAGE_TAG)

# --- Helpers ---
check-project:
	@if [ -z "$(PROJECT_ID)" ]; then \
		echo "PROJECT_ID is required. Example: make docker-release PROJECT_ID=my-gcp-project"; \
		exit 1; \
	fi

check-gcloud:
	@command -v gcloud >/dev/null 2>&1 || { \
		echo "gcloud is not installed. Install Google Cloud SDK first."; \
		exit 1; \
	}

# --- Protocol Buffer generation ---
proto:
	@echo "Generating Go code from proto..."
	protoc --go_out=. --go_opt=paths=source_relative \
		--go-grpc_out=. --go-grpc_opt=paths=source_relative \
		-I . api/tempconv.proto
	@echo "Proto generation complete."

# --- Backend (Go) ---
backend: proto
	@echo "Building backend..."
	cd backend && go build -o bin/server ./cmd/server
	@echo "Backend built: backend/bin/server"

backend-run: backend
	cd backend && ./bin/server

# --- Frontend (Flutter) ---
frontend:
	@echo "Building Flutter web app..."
	cd frontend && flutter pub get && flutter build web --no-wasm-dry-run
	@echo "Frontend built: frontend/build/web"

# --- Docker builds (AMD64 for GKE) ---
docker-build:
	@echo "Building Docker images for linux/amd64..."
	docker build --platform linux/amd64 -t tempconv-backend:latest -f backend/Dockerfile .
	docker build --platform linux/amd64 -t tempconv-frontend:latest -f frontend/Dockerfile frontend
	@echo "Docker images built."

# --- Artifact Registry + GKE release flow ---
ar-create: check-project check-gcloud
	gcloud artifacts repositories describe $(AR_REPO) --location=$(REGION) --project=$(PROJECT_ID) >/dev/null 2>&1 || \
	gcloud artifacts repositories create $(AR_REPO) --repository-format=docker --location=$(REGION) --project=$(PROJECT_ID)

ar-auth: check-project check-gcloud
	gcloud auth configure-docker $(REGION)-docker.pkg.dev --quiet

docker-build-gke: check-project
	@echo "Building release images for linux/amd64..."
	docker build --platform linux/amd64 -t $(BACKEND_IMAGE) -f backend/Dockerfile .
	docker build --platform linux/amd64 -t $(FRONTEND_IMAGE) -f frontend/Dockerfile \
		--build-arg GRPC_BACKEND_URL=$(FRONTEND_BACKEND_URL) frontend
	@echo "Built:"
	@echo "  $(BACKEND_IMAGE)"
	@echo "  $(FRONTEND_IMAGE)"

docker-push: check-project
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

docker-release: ar-create ar-auth docker-build-gke docker-push

gke-create: check-project check-gcloud
	gcloud container clusters create $(CLUSTER_NAME) \
		--project=$(PROJECT_ID) --region=$(REGION) \
		--machine-type=e2-small --num-nodes=2

gke-creds: check-project check-gcloud
	gcloud container clusters get-credentials $(CLUSTER_NAME) --region $(REGION) --project $(PROJECT_ID)

gke-apply:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/backend-deployment.yaml
	kubectl apply -f k8s/frontend-deployment.yaml
	kubectl apply -f k8s/ingress.yaml

gke-deploy: check-project docker-release gke-apply
	kubectl -n tempconv set image deployment/tempconv-backend backend=$(BACKEND_IMAGE)
	kubectl -n tempconv set image deployment/tempconv-frontend frontend=$(FRONTEND_IMAGE)

# --- Tests ---
test: proto
	go test -v ./backend/cmd/server/...

# --- Load testing ---
loadtest:
	@echo "Running load tests..."
	cd loadtest && k6 run loadtest.js
	@echo "Load test complete."

# --- Clean ---
clean:
	rm -rf backend/bin
	rm -rf frontend/build
	rm -rf api/*.pb.go
	rm -rf loadtest/results/*
