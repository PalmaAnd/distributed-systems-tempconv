// TempConv gRPC load test. From backend/: go run ./cmd/loadtest [flags]
// Target default: localhost:8080 (gRPC backend). For K8s: port-forward tempconv-backend 8080:8080.
package main

import (
	"context"
	"flag"
	"log"
	"sync"
	"sync/atomic"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	tempconv_v1 "github.com/tempconv/backend/internal/pb/tempconv/v1"
)

var (
	targetAddr  = flag.String("target", "localhost:8080", "gRPC backend address")
	concurrency = flag.Int("c", 20, "concurrent goroutines")
	duration    = flag.Duration("d", 30*time.Second, "test duration")
)

func main() {
	flag.Parse()
	conn, err := grpc.NewClient(*targetAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("dial: %v", err)
	}
	defer conn.Close()
	client := tempconv_v1.NewTempConvClient(conn)

	var ok, fail int64
	ctx := context.Background()
	deadline := time.Now().Add(*duration)
	var wg sync.WaitGroup
	for i := 0; i < *concurrency; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for time.Now().Before(deadline) {
				res, err := client.CelsiusToFahrenheit(ctx, &tempconv_v1.Value{Value: 25})
				if err != nil {
					atomic.AddInt64(&fail, 1)
					continue
				}
				if res.Value != 77 {
					atomic.AddInt64(&fail, 1)
					continue
				}
				atomic.AddInt64(&ok, 1)

				res, err = client.FahrenheitToCelsius(ctx, &tempconv_v1.Value{Value: 212})
				if err != nil {
					atomic.AddInt64(&fail, 1)
					continue
				}
				if res.Value != 100 {
					atomic.AddInt64(&fail, 1)
					continue
				}
				atomic.AddInt64(&ok, 1)
			}
		}()
	}
	wg.Wait()
	total := ok + fail
	log.Printf("ok=%d fail=%d total=%d", ok, fail, total)
	if total > 0 {
		log.Printf("error rate=%.2f%%", 100*float64(fail)/float64(total))
	}
}
