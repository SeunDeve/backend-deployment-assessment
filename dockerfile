# ─── Stage 1: Builder ───────────────────────────────────────────
FROM golang:1.25-alpine AS builder

# Install CA certificates
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy dependency files first (better layer caching)
COPY go.mod go.sum ./
RUN go mod download

# Copy only necessary source files
COPY cmd/ ./cmd/
COPY internal/ ./internal/
COPY docs/ ./docs/

# Build the binary (matches your Makefile build command)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o ./bin/much-to-do ./cmd/api/main.go

# ─── Stage 2: Final lean image ──────────────────────────────────
FROM alpine:3.20

WORKDIR /app

# Copy CA certificates for HTTPS/MongoDB TLS calls
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy only the compiled binary
COPY --from=builder /app/bin/much-to-do .

# Copy swagger docs if served at runtime
COPY --from=builder /app/docs ./docs

# Create non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose application port
EXPOSE 8080

# Health check against /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the binary
ENTRYPOINT ["./much-to-do"]