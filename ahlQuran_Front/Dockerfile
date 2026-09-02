# ── Stage 1: Build Flutter Web ───────────────────────────────────────────────
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency manifest first (cache layer)
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the full source
COPY . .

# Ensure .env exists (Flutter reads it as an asset at runtime)
# We write the value supplied at build time via ARG, falling back to localhost.
ARG API_BASE_URL=http://localhost:8000
ARG API_VERSION=v1
ARG ENVIRONMENT=development
RUN printf "API_BASE_URL=%s\nAPI_VERSION=%s\nENVIRONMENT=%s\n" \
      "$API_BASE_URL" "$API_VERSION" "$ENVIRONMENT" > .env

# Build for web (release, disable service worker to avoid stale cached bundles)
RUN flutter build web --release --pwa-strategy=none

# ── Stage 2: Serve with nginx ─────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Remove default nginx content
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# nginx config: serve SPA with HTML5 history fallback and proxy API to backend
RUN printf 'server {\n\
    listen 80;\n\
    root /usr/share/nginx/html;\n\
    index index.html;\n\
    location /api/ {\n\
        proxy_pass http://backend:8000;\n\
        proxy_http_version 1.1;\n\
        proxy_set_header Host $http_host;\n\
        proxy_set_header X-Real-IP $remote_addr;\n\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\n\
        proxy_set_header X-Forwarded-Host $http_host;\n\
        proxy_set_header X-Forwarded-Port $server_port;\n\
        proxy_set_header X-Forwarded-Proto $scheme;\n\
    }\n\
    location / {\n\
        try_files $uri $uri/ /index.html;\n\
    }\n\
    location = /index.html {\n\
        add_header Cache-Control "no-store, no-cache, must-revalidate";\n\
    }\n\
    gzip on;\n\
    gzip_types text/plain text/css application/javascript application/json\n\
               application/wasm image/svg+xml;\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
