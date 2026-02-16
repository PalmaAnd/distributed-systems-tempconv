# TempConv Frontend - AMD64 for GKE
# Stage 1: Build Flutter web
FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy pubspec first for layer caching
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .

# Build web (--no-wasm-dry-run avoids wasm issues in CI)
ARG GRPC_BACKEND_URL=http://localhost:8080
RUN flutter build web --no-wasm-dry-run --release \
  --dart-define=GRPC_BACKEND_URL=$GRPC_BACKEND_URL

# Stage 2: Serve with nginx
FROM --platform=linux/amd64 nginx:alpine

# Copy built assets
COPY --from=builder /app/build/web /usr/share/nginx/html

# nginx config for SPA
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
