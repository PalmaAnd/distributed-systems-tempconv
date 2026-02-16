# TempConv - Build and deployment automation
.PHONY: proto backend frontend docker-build loadtest test clean

# Default target
all: proto backend frontend

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
