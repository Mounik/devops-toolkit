# Dockerfile template with health check best practices

FROM python:3.12-slim AS base

# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc=4:12.* \
    && rm -rf /var/lib/apt/lists/*

# Security: run as non-root
RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Install deps first (layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# Switch to non-root user
USER appuser

EXPOSE 8080

CMD ["python", "-m", "app"]