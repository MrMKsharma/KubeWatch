package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
	"go.opentelemetry.io/otel/trace"
)

var tracer trace.Tracer

func init() {
	ctx := context.Background()

	exporter, err := otlptrace.New(ctx,
		otlptracegrpc.NewClient(
			otlptracegrpc.WithEndpoint("otel-collector:4317"),
			otlptracegrpc.WithInsecure(),
		),
	)
	if err != nil {
		log.Printf("Failed to create exporter: %v", err)
		return
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("inventory"),
			semconv.ServiceVersionKey.String("1.0.0"),
		),
	)
	if err != nil {
		log.Printf("Failed to create resource: %v", err)
		return
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)

	tracer = tp.Tracer("inventory")
}

func main() {
	// Check inventory endpoint
	http.HandleFunc("/check", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /check")
		defer span.End()

		// Simulate inventory check
		time.Sleep(50 * time.Millisecond)

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Stock available: 150 units\n")
	})

	// Status endpoint
	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /status")
		defer span.End()

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Inventory service running\n")
	})

	log.Println("Inventory service listening on :8083")
	if err := http.ListenAndServe(":8083", otelhttp.NewHandler(http.DefaultServeMux, "inventory")); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
