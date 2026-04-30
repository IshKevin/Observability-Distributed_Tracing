import os
import time
import logging
import random

import requests
from flask import Flask, jsonify, request, g
from pythonjsonlogger import jsonlogger
from prometheus_client import (
    Counter, Histogram, Gauge,
    generate_latest, CONTENT_TYPE_LATEST,
)
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.trace import StatusCode

# OpenTelemetry setup
_resource = Resource.create({
    "service.name": os.getenv("OTEL_SERVICE_NAME", "flask-app"),
    "service.version": "1.0.0",
    "deployment.environment": os.getenv("ENVIRONMENT", "development"),
})
_provider = TracerProvider(resource=_resource)
_otlp_exporter = OTLPSpanExporter(
    endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://jaeger:4317"),
    insecure=True,
)
_provider.add_span_processor(BatchSpanProcessor(_otlp_exporter))
trace.set_tracer_provider(_provider)
tracer = trace.get_tracer(__name__)


class _TraceContextFilter(logging.Filter):
    def filter(self, record):
        span = trace.get_current_span()
        ctx = span.get_span_context()
        record.trace_id = format(ctx.trace_id, "032x") if ctx.is_valid else "0" * 32
        record.span_id = format(ctx.span_id, "016x") if ctx.is_valid else "0" * 16
        return True


_handler = logging.StreamHandler()
_handler.setFormatter(
    jsonlogger.JsonFormatter(
        "%(asctime)s %(name)s %(levelname)s %(message)s %(trace_id)s %(span_id)s"
    )
)
_handler.addFilter(_TraceContextFilter())
logging.root.setLevel(logging.INFO)
logging.root.addHandler(_handler)
logger = logging.getLogger(__name__)

app = Flask(__name__)
FlaskInstrumentor().instrument_app(app, excluded_urls="metrics,health")
RequestsInstrumentor().instrument()


REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "http_status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0],
)
REQUESTS_IN_PROGRESS = Gauge(
    "http_requests_in_progress",
    "HTTP requests currently in progress",
    ["method", "endpoint"],
)
ERROR_COUNT = Counter(
    "http_errors_total",
    "Total HTTP errors (4xx/5xx)",
    ["method", "endpoint", "http_status"],
)


@app.before_request
def _start_timer():
    g.start_time = time.time()
    REQUESTS_IN_PROGRESS.labels(
        method=request.method, endpoint=request.endpoint or "unknown"
    ).inc()


@app.after_request
def _record_metrics(response):
    duration = time.time() - g.start_time
    endpoint = request.endpoint or "unknown"
    status = str(response.status_code)

    REQUEST_COUNT.labels(method=request.method, endpoint=endpoint, http_status=status).inc()
    REQUEST_LATENCY.labels(method=request.method, endpoint=endpoint).observe(duration)
    REQUESTS_IN_PROGRESS.labels(method=request.method, endpoint=endpoint).dec()

    if response.status_code >= 400:
        ERROR_COUNT.labels(method=request.method, endpoint=endpoint, http_status=status).inc()

    logger.info(
        "request completed",
        extra={
            "method": request.method,
            "path": request.path,
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2),
        },
    )
    return response


@app.route("/metrics")
def metrics_endpoint():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}


@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "flask-app"})


@app.route("/")
def index():
    with tracer.start_as_current_span("index-handler") as span:
        span.set_attribute("http.route", "/")
        logger.info("index endpoint called")
        return jsonify({
            "message": "Advanced Monitoring Flask App",
            "version": "1.0.0",
            "endpoints": [
                "/health", "/metrics",
                "/api/users", "/api/simulate-error",
                "/api/simulate-latency", "/api/external-call",
            ],
        })


@app.route("/api/users")
def get_users():
    with tracer.start_as_current_span("get-users") as span:
        time.sleep(random.uniform(0.01, 0.15))
        users = [
            {"id": 1, "name": "Alice", "role": "admin"},
            {"id": 2, "name": "Bob", "role": "user"},
            {"id": 3, "name": "Charlie", "role": "user"},
        ]
        span.set_attribute("users.count", len(users))
        logger.info("users fetched", extra={"count": len(users)})
        return jsonify({"users": users, "total": len(users)})


@app.route("/api/simulate-error")
def simulate_error():
    with tracer.start_as_current_span("simulate-error") as span:
        msg = "Simulated internal server error"
        span.record_exception(Exception(msg))
        span.set_status(StatusCode.ERROR, msg)
        logger.error("simulated error triggered", extra={"error_type": "simulated"})
        return jsonify({"error": msg, "code": "SIMULATED_ERROR"}), 500


@app.route("/api/simulate-latency")
def simulate_latency():
    delay = min(float(request.args.get("delay", 0.5)), 10.0)
    with tracer.start_as_current_span("simulate-latency") as span:
        span.set_attribute("latency.delay_seconds", delay)
        time.sleep(delay)
        logger.info("latency simulation done", extra={"delay_seconds": delay})
        return jsonify({"message": f"responded after {delay:.2f}s", "delay": delay})


@app.route("/alerts", methods=["POST"])
def receive_alerts():
    payload = request.get_json(silent=True) or {}
    for alert in payload.get("alerts", []):
        logger.warning(
            "alertmanager alert received",
            extra={
                "alert_name": alert.get("labels", {}).get("alertname"),
                "severity": alert.get("labels", {}).get("severity"),
                "status": alert.get("status"),
                "summary": alert.get("annotations", {}).get("summary"),
            },
        )
    return jsonify({"received": len(payload.get("alerts", []))}), 200


@app.route("/api/external-call")
def external_call():
    with tracer.start_as_current_span("external-http-call") as span:
        try:
            resp = requests.get("https://httpbin.org/get", timeout=5)
            span.set_attribute("http.status_code", resp.status_code)
            logger.info("external call ok", extra={"status_code": resp.status_code})
            return jsonify({"status": resp.status_code, "message": "external call successful"})
        except Exception as exc:
            span.record_exception(exc)
            span.set_status(StatusCode.ERROR, str(exc))
            logger.error("external call failed", extra={"error": str(exc)})
            return jsonify({"error": str(exc)}), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
