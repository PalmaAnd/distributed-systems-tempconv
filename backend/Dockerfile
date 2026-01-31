# Build stage (AMD64 for GKE)
FROM golang:1.21-alpine AS builder
WORKDIR /app
RUN apk add --no-cache ca-certificates
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /tempconv-backend .

# Runtime stage
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /tempconv-backend .
EXPOSE 8080
USER nobody
CMD ["./tempconv-backend"]
