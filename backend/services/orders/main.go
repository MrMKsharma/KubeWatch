package main

import (
	"context"
	"fmt"
	"io"
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
			semconv.ServiceNameKey.String("orders"),
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

	tracer = tp.Tracer("orders")
}

func main() {
	// Create order endpoint
	http.HandleFunc("/create", func(w http.ResponseWriter, r *http.Request) {
		ctx, span := tracer.Start(r.Context(), "POST /create")
		defer span.End()

		// Call inventory service
		invResp, err := callService(ctx, "http://inventory:8083/check")
		if err != nil {
			http.Error(w, fmt.Sprintf("Inventory check failed: %v", err), http.StatusInternalServerError)
			return
		}

		// Call payments service
		payResp, err := callService(ctx, "http://payments:8082/process")
		if err != nil {
			http.Error(w, fmt.Sprintf("Payment failed: %v", err), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintf(w, "Order ID: 12345\nInventory: %s\nPayment: %s\n", invResp, payResp)
	})

	// Status endpoint
	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /status")
		defer span.End()

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Orders service running\n")
	})

	log.Println("Orders service listening on :8081")
	if err := http.ListenAndServe(":8081", otelhttp.NewHandler(http.DefaultServeMux, "orders")); err != nil {
		log.Fatalf("Server error: %v", err)
	}
}

func callService(ctx context.Context, url string) (string, error) {
	ctx, span := tracer.Start(ctx, "callService")
	defer span.End()

	client := &http.Client{
		Timeout: 5 * time.Second,
		Transport: otelhttp.NewTransport(http.DefaultTransport),
	}

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return "", err
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	return string(body), err
}
