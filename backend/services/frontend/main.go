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

	// Create OTLP exporter
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

	// Create resource
	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("frontend"),
			semconv.ServiceVersionKey.String("1.0.0"),
		),
	)
	if err != nil {
		log.Printf("Failed to create resource: %v", err)
		return
	}

	// Create tracer provider
	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)

	tracer = tp.Tracer("frontend")
}

func main() {
	// Main page
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /")
		defer span.End()

		w.Header().Set("Content-Type", "text/html")
		fmt.Fprint(w, `
			<html>
			<head><title>KubeWatch Demo</title></head>
			<body>
				<h1>Welcome to KubeWatch Frontend</h1>
				<p>This service demonstrates distributed tracing.</p>
				<ul>
					<li><a href="/order">Place Order</a></li>
					<li><a href="/status">Check Status</a></li>
				</ul>
			</body>
			</html>
		`)
	})

	// Order endpoint
	http.HandleFunc("/order", func(w http.ResponseWriter, r *http.Request) {
		ctx, span := tracer.Start(r.Context(), "GET /order")
		defer span.End()

		// Call orders service
		orderResp, err := callService(ctx, "http://orders:8081/create")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprintf(w, "Order created: %s\n", orderResp)
	})

	// Status endpoint
	http.HandleFunc("/status", func(w http.ResponseWriter, r *http.Request) {
		_, span := tracer.Start(r.Context(), "GET /status")
		defer span.End()

		w.Header().Set("Content-Type", "text/plain")
		fmt.Fprint(w, "Frontend is running\n")
	})

	log.Println("Frontend listening on :8080")
	if err := http.ListenAndServe(":8080", otelhttp.NewHandler(http.DefaultServeMux, "frontend")); err != nil {
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
