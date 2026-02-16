package main

import (
	"context"

	"tempconv/api"

	"testing"
)

func TestCelsiusToFahrenheit(t *testing.T) {
	s := &server{}
	ctx := context.Background()

	tests := []struct {
		input    float64
		expected float64
	}{
		{0, 32},
		{100, 212},
		{-40, -40},
		{25, 77},
	}

	for _, tt := range tests {
		resp, err := s.CelsiusToFahrenheit(ctx, &api.CelsiusToFahrenheitRequest{Value: tt.input})
		if err != nil {
			t.Fatalf("CelsiusToFahrenheit(%v) error: %v", tt.input, err)
		}
		if resp.Value != tt.expected {
			t.Errorf("CelsiusToFahrenheit(%v) = %v, want %v", tt.input, resp.Value, tt.expected)
		}
	}
}

func TestFahrenheitToCelsius(t *testing.T) {
	s := &server{}
	ctx := context.Background()

	tests := []struct {
		input    float64
		expected float64
	}{
		{32, 0},
		{212, 100},
		{-40, -40},
	}

	for _, tt := range tests {
		resp, err := s.FahrenheitToCelsius(ctx, &api.FahrenheitToCelsiusRequest{Value: tt.input})
		if err != nil {
			t.Fatalf("FahrenheitToCelsius(%v) error: %v", tt.input, err)
		}
		if resp.Value != tt.expected {
			t.Errorf("FahrenheitToCelsius(%v) = %v, want %v", tt.input, resp.Value, tt.expected)
		}
	}
}
