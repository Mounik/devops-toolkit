# Dockerfile template — Node.js with health check

FROM node:20-slim AS base

RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

RUN groupadd -r appuser && useradd -r -g appuser -d /app -s /sbin/nologin appuser

WORKDIR /app

# Install deps (layer caching)
COPY package.json package-lock.json ./
RUN npm ci --only=production && npm cache clean --force

COPY . .

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

USER appuser

EXPOSE 3000

CMD ["node", "server.js"]