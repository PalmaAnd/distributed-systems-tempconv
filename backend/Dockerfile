# TempConv Backend - AMD64 for GKE
# Build from project root: docker build -f backend/Dockerfile .
FROM --platform=linux/amd64 golang:1.24-alpine AS builder

WORKDIR /app

RUN apk add --no-cache protobuf

COPY go.mod go.sum ./
RUN go mod download 2>/dev/null || true
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.36.6 \
  && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1
ENV PATH="/go/bin:${PATH}"

COPY api/ ./api/
COPY backend/ ./backend/

RUN protoc --go_out=. --go_opt=paths=source_relative \
  --go-grpc_out=. --go-grpc_opt=paths=source_relative \
  -I . api/tempconv.proto

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /server ./backend/cmd/server

# Runtime
FROM --platform=linux/amd64 alpine:3.19

RUN apk add --no-cache ca-certificates

WORKDIR /app
COPY --from=builder /server .

EXPOSE 50051 8080

ENTRYPOINT ["./server"]
