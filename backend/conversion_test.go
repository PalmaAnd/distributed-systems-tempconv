package main

import (
	"testing"
)

func TestCelsiusToFahrenheit(t *testing.T) {
	tests := []struct {
		celsius    float64
		fahrenheit float64
	}{
		{0, 32},
		{100, 212},
		{-40, -40},
		{37, 98.6},
	}
	for _, tt := range tests {
		got := celsiusToFahrenheit(tt.celsius)
		if got != tt.fahrenheit {
			t.Errorf("celsiusToFahrenheit(%v) = %v, want %v", tt.celsius, got, tt.fahrenheit)
		}
	}
}

func TestFahrenheitToCelsius(t *testing.T) {
	tests := []struct {
		fahrenheit float64
		celsius    float64
	}{
		{32, 0},
		{212, 100},
		{-40, -40},
		{98.6, 37},
	}
	for _, tt := range tests {
		got := fahrenheitToCelsius(tt.fahrenheit)
		if got != tt.celsius {
			t.Errorf("fahrenheitToCelsius(%v) = %v, want %v", tt.fahrenheit, got, tt.celsius)
		}
	}
}
