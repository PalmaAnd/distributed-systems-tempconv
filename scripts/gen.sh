#!/usr/bin/env bash
# Generate Go and Dart code from proto. Requires:
#   - protoc, protoc-gen-go, protoc-gen-go-grpc (Go)
#   - protoc-gen-dart (Dart: dart pub global activate protoc_plugin; PATH includes $HOME/.pub-cache/bin)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROTO_ROOT="$ROOT/proto"
PROTO_FILE="$PROTO_ROOT/tempconv/v1/tempconv.proto"

# Go
GO_OUT="$ROOT/backend/internal/pb"
mkdir -p "$GO_OUT"
protoc -I "$PROTO_ROOT" \
  --go_out="$GO_OUT" --go_opt=paths=source_relative \
  --go-grpc_out="$GO_OUT" --go-grpc_opt=paths=source_relative \
  "$PROTO_FILE"

# Dart (for Flutter gRPC-Web client)
DART_OUT="$ROOT/frontend/lib/generated"
mkdir -p "$DART_OUT"
export PATH="${PATH}:${HOME}/.pub-cache/bin"
protoc -I "$PROTO_ROOT" \
  --dart_out=grpc:"$DART_OUT" \
  "$PROTO_FILE"

echo "Generated Go -> $GO_OUT, Dart -> $DART_OUT"
