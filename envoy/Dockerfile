# Envoy proxy for gRPC-Web (AMD64 for GKE)
FROM envoyproxy/envoy:v1.31-latest
COPY envoy.yaml /etc/envoy/envoy.yaml
CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml", "-l", "info"]
