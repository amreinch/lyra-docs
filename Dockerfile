# Dockerfile for Lyra Documentation
# Multi-stage build: Build docs with MkDocs, serve with Nginx

# Stage 1: Build documentation
FROM python:3.11-slim AS builder

WORKDIR /docs

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy documentation source
COPY mkdocs.yml .
COPY docs/ ./docs/

# Build static site
RUN mkdocs build --clean

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built documentation from builder stage
COPY --from=builder /docs/site /usr/share/nginx/html

# Copy custom nginx configuration (optional)
COPY nginx-docker.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Nginx runs in foreground by default
CMD ["nginx", "-g", "daemon off;"]
