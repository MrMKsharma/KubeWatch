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
			semconv.ServiceNameKey.String("payments"),
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

	tracer = tp.Tracer("payments")
}

func main() {
	// Process payment endpoint
	http.HandleFunc("/process", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "POST /process")
		defer span.End()

		// Simulate payment processing
		time.Sleep(100 * time.Millisecond)

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Payment processed: $99.99\n")
	})

	// Status endpoint
	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /status")
		defer span.End()

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Payments service running\n")
	})

	log.Println("Payments service listening on :8082")
	if err := http.ListenAndServe(":8082", otelhttp.NewHandler(http.DefaultServeMux, "payments")); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}
