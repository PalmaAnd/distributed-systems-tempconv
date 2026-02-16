package main

import (
	"context"

	"tempconv/api"
)

type server struct {
	api.UnimplementedTempConvServiceServer
}

func (s *server) CelsiusToFahrenheit(ctx context.Context, req *api.CelsiusToFahrenheitRequest) (*api.CelsiusToFahrenheitResponse, error) {
	f := req.Value*9/5 + 32
	return &api.CelsiusToFahrenheitResponse{Value: f}, nil
}

func (s *server) FahrenheitToCelsius(ctx context.Context, req *api.FahrenheitToCelsiusRequest) (*api.FahrenheitToCelsiusResponse, error) {
	c := (req.Value - 32) * 5 / 9
	return &api.FahrenheitToCelsiusResponse{Value: c}, nil
}

