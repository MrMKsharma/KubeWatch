package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
	"go.opentelemetry.io/otel/trace"
)

// CORS middleware
func corsMiddleware(next http.Handler) http.Handler {
	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	originsMap := make(map[string]bool)
	if allowedOrigins != "" {
		// Split comma-separated origins
		var current string
		for _, c := range allowedOrigins {
			if c == ',' {
				if current != "" {
					originsMap[current] = true
					current = ""
				}
			} else {
				current += string(c)
			}
		}
		if current != "" {
			originsMap[current] = true
		}
	} else {
		// Default to localhost for development
		originsMap["http://localhost:3000"] = true
		originsMap["http://localhost:3001"] = true
		originsMap["http://localhost:5173"] = true
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		if originsMap[origin] || allowedOrigins == "*" {
			w.Header().Set("Access-Control-Allow-Origin", origin)
		}
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS") // Only allow read methods for public API
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Content-Security-Policy", "default-src 'self'")

		// Handle preflight requests
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

var tracer trace.Tracer

func init() {
	ctx := context.Background()

	otelEnabled := os.Getenv("OTEL_ENABLED")
	if otelEnabled != "true" {
		log.Println("OpenTelemetry tracing is disabled (set OTEL_ENABLED=true to enable)")
		tracer = nil
		return
	}

	otelEndpoint := os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")
	if otelEndpoint == "" {
		otelEndpoint = "otel-collector.tracing.svc.cluster.local:4317"
	}

	exporter, err := otlptrace.New(ctx,
		otlptracegrpc.NewClient(
			otlptracegrpc.WithEndpoint(otelEndpoint),
			otlptracegrpc.WithInsecure(),
		),
	)
	if err != nil {
		log.Printf("Failed to create exporter: %v", err)
		log.Println("OpenTelemetry tracing will be disabled")
		tracer = nil
		return
	}

	res, err := resource.New(ctx,
		resource.WithAttributes(
			semconv.ServiceNameKey.String("kubewatch-api"),
			semconv.ServiceVersionKey.String("1.0.0"),
		),
	)
	if err != nil {
		log.Printf("Failed to create resource: %v", err)
		log.Println("OpenTelemetry tracing will be disabled")
		tracer = nil
		return
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(res),
	)
	otel.SetTracerProvider(tp)
	tracer = tp.Tracer("kubewatch-api")
	log.Println("OpenTelemetry tracing initialized successfully")
}

// --- Data Structures ---

type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}

type StatusResponse struct {
	Status    string   `json:"status"`
	Timestamp string   `json:"timestamp"`
	Services  []string `json:"services"`
}

type MetricDataPoint struct {
	Time string `json:"time"`
	CPU  int    `json:"cpu"`
	Mem  int    `json:"mem"`
	Net  int    `json:"net"`
}

type MetricsResponse struct {
	Timestamp string            `json:"timestamp"`
	Data      []MetricDataPoint `json:"data"`
}

type NodeStats struct {
	Name   string `json:"name"`
	Status string `json:"status"`
	CPU    string `json:"cpu"`
	Mem    string `json:"mem"`
	Pods   int    `json:"pods"`
}

type NodesResponse struct {
	Timestamp string      `json:"timestamp"`
	Nodes     []NodeStats `json:"nodes"`
}

type Alert struct {
	ID       int    `json:"id"`
	Severity string `json:"severity"`
	Message  string `json:"message"`
	Time     string `json:"time"`
}

type AlertsResponse struct {
	Timestamp string  `json:"timestamp"`
	Alerts    []Alert `json:"alerts"`
}

// --- Handler Functions ---

func healthHandler(w http.ResponseWriter, r *http.Request) {
	if tracer != nil {
		_, span := tracer.Start(r.Context(), "healthHandler")
		defer span.End()
	}

	response := HealthResponse{
		Status:  "ok",
		Version: "1.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response)
}

func statusHandler(w http.ResponseWriter, r *http.Request) {
	if tracer != nil {
		_, span := tracer.Start(r.Context(), "statusHandler")
		defer span.End()
	}

	response := StatusResponse{
		Status:    "healthy",
		Timestamp: time.Now().Format(time.RFC3339),
		Services: []string{
			"prometheus",
			"loki",
			"tempo",
			"kubernetes",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response)
}

func metricsHandler(w http.ResponseWriter, r *http.Request) {
	if tracer != nil {
		_, span := tracer.Start(r.Context(), "metricsHandler")
		defer span.End()
	}

	now := time.Now()
	var data []MetricDataPoint
	for i := 11; i >= 0; i-- {
		t := now.Add(-time.Duration(i*5) * time.Minute)
		data = append(data, MetricDataPoint{
			Time: t.Format("15:04"),
			CPU:  rand.Intn(40) + 20,
			Mem:  rand.Intn(30) + 40,
			Net:  rand.Intn(100) + 50,
		})
	}

	response := MetricsResponse{
		Timestamp: now.Format(time.RFC3339),
		Data:      data,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response)
}

func nodesHandler(w http.ResponseWriter, r *http.Request) {
	if tracer != nil {
		_, span := tracer.Start(r.Context(), "nodesHandler")
		defer span.End()
	}

	nodes := []NodeStats{
		{
			Name:   "kind-control-plane",
			Status: "Ready",
			CPU:    fmt.Sprintf("%d%%", rand.Intn(50)+30),
			Mem:    fmt.Sprintf("%d%%", rand.Intn(40)+40),
			Pods:   12 + rand.Intn(5),
		},
		{
			Name:   "kind-worker",
			Status: "Ready",
			CPU:    fmt.Sprintf("%d%%", rand.Intn(40)+20),
			Mem:    fmt.Sprintf("%d%%", rand.Intn(35)+35),
			Pods:   8 + rand.Intn(4),
		},
	}

	response := NodesResponse{
		Timestamp: time.Now().Format(time.RFC3339),
		Nodes:     nodes,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response)
}

func alertsHandler(w http.ResponseWriter, r *http.Request) {
	if tracer != nil {
		_, span := tracer.Start(r.Context(), "alertsHandler")
		defer span.End()
	}

	alerts := []Alert{
		{
			ID:       1,
			Severity: "warning",
			Message:  "High CPU usage on node kind-worker",
			Time:     "2 min ago",
		},
		{
			ID:       2,
			Severity: "info",
			Message:  "New pod deployed in default namespace",
			Time:     "5 min ago",
		},
		{
			ID:       3,
			Severity: "success",
			Message:  "All pods are healthy",
			Time:     "10 min ago",
		},
	}

	response := AlertsResponse{
		Timestamp: time.Now().Format(time.RFC3339),
		Alerts:    alerts,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(response)
}

func main() {
	// Seed random number generator
	rand.Seed(time.Now().UnixNano())

	r := mux.NewRouter()

	// API endpoints
	r.HandleFunc("/api/v1/health", healthHandler).Methods("GET")
	r.HandleFunc("/api/v1/status", statusHandler).Methods("GET")
	r.HandleFunc("/api/v1/metrics", metricsHandler).Methods("GET")
	r.HandleFunc("/api/v1/nodes", nodesHandler).Methods("GET")
	r.HandleFunc("/api/v1/alerts", alertsHandler).Methods("GET")

	var handler http.Handler
	if tracer != nil {
		// Wrap router with OpenTelemetry instrumentation and CORS middleware
		otelHandler := otelhttp.NewHandler(r, "kubewatch-api")
		handler = corsMiddleware(otelHandler)
	} else {
		// Just use CORS middleware
		handler = corsMiddleware(r)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8090"
	}

	log.Printf("KubeWatch API listening on :%s", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%s", port), handler))
}
