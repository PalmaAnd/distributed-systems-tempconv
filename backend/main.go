package main

import (
	"context"
	"log"
	"net"
	"net/http"

	"google.golang.org/grpc"

	tempconv_v1 "github.com/tempconv/backend/internal/pb/tempconv/v1"
)

type server struct {
	tempconv_v1.UnimplementedTempConvServer // for forward compatibility
}

func (s *server) CelsiusToFahrenheit(ctx context.Context, in *tempconv_v1.Value) (*tempconv_v1.Value, error) {
	return &tempconv_v1.Value{Value: celsiusToFahrenheit(in.Value)}, nil
}

func (s *server) FahrenheitToCelsius(ctx context.Context, in *tempconv_v1.Value) (*tempconv_v1.Value, error) {
	return &tempconv_v1.Value{Value: fahrenheitToCelsius(in.Value)}, nil
}

func celsiusToFahrenheit(c float64) float64 {
	return c*9/5 + 32
}

func fahrenheitToCelsius(f float64) float64 {
	return (f - 32) * 5 / 9
}

func main() {
	lis, err := net.Listen("tcp", ":8080")
	if err != nil {
		log.Fatalf("listen: %v", err)
	}
	srv := grpc.NewServer()
	tempconv_v1.RegisterTempConvServer(srv, &server{})

	// HTTP health on :8081 for Kubernetes probes (gRPC is on :8080)
	go func() {
		mux := http.NewServeMux()
		mux.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusOK)
			w.Write([]byte("ok"))
		})
		if err := http.ListenAndServe(":8081", mux); err != nil {
			log.Fatalf("health server: %v", err)
		}
	}()

	log.Println("TempConv gRPC server listening on :8080, health on :8081")
	if err := srv.Serve(lis); err != nil {
		log.Fatalf("serve: %v", err)
	}
}
