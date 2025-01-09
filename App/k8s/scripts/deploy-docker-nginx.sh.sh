#!/bin/bash

# Script metadata
VERSION="2.0.0"
LAST_UPDATED="2025-01-09"
AUTHOR="mericalp"
LOG_FILE="/var/log/deploy-docker-nginx.log"

# Strict mode ve error handling
set -euo pipefail
trap 'error_handler $? $LINENO $BASH_COMMAND' ERR

# Error handling function
error_handler() {
    local exit_code=$1
    local line_number=$2
    local command=$3
    log_error "Error occurred in command '$command' at line $line_number with exit code $exit_code"
    cleanup_on_error
}

# Cleanup function
cleanup_on_error() {
    log_info "Performing cleanup after error..."
    docker-compose down 2>/dev/null || true
    sudo systemctl stop nginx 2>/dev/null || true
}

# Logging functions
log_info() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [INFO] $*" | tee -a "$LOG_FILE"; }
log_error() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [ERROR] $*" >&2 | tee -a "$LOG_FILE"; }

# Health check function
check_service_health() {
    local service=$1
    local port=$2
    local max_attempts=30
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:${port}/health" >/dev/null; then
            log_info "$service is healthy"
            return 0
        fi
        log_info "Waiting for $service to become healthy (attempt $attempt/$max_attempts)"
        sleep 2
        ((attempt++))
    done
    log_error "$service failed health check"
    return 1
}

# Backup function
backup_current_state() {
    local backup_dir="/opt/App/backups/$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup at $backup_dir"
    mkdir -p "$backup_dir"
    
    # Backup configurations
    cp /etc/nginx/nginx.conf "$backup_dir/" 2>/dev/null || true
    docker-compose config > "$backup_dir/docker-compose.yml" 2>/dev/null || true
    
    # Backup environment files
    if [ -f .env ]; then
        cp .env "$backup_dir/"
    fi
    
    # Create backup archive
    tar -czf "$backup_dir.tar.gz" "$backup_dir"
    rm -rf "$backup_dir"
    log_info "Backup created at $backup_dir.tar.gz"
}

# Main deployment function
main() {
    log_info "Starting deployment at $(date)"
    
    # Create backup before deployment
    backup_current_state

    # Install and configure Nginx
    log_info "Installing and configuring Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx

    # Create Nginx configuration
    log_info "Creating Nginx configuration..."
    cat << 'EOF' | sudo tee /etc/nginx/nginx.conf
    [Nginx configuration from above goes here]
EOF

    # Restart Nginx
    log_info "Restarting Nginx..."
    sudo systemctl restart nginx

    # Create Docker network
    log_info "Creating Docker network..."
    docker network create todo-network || true

    # Stop and remove existing containers
    log_info "Cleaning up existing containers..."
    docker stop mongodb frontend backend 2>/dev/null || true
    docker rm mongodb frontend backend 2>/dev/null || true

    # Start MongoDB container
    log_info "Starting MongoDB container..."
    docker run -d --name mongodb \
        --network todo-network \
        -p 27017:27017 \
        -v mongodb_data:/data/db \
        mongo:4.4

    # Docker Hub login
    log_info "Logging into Docker Hub..."
    echo "$DOCKER_PASSWORD" | docker login --username "$DOCKER_USERNAME" --password-stdin

    # Deploy backend
    log_info "Deploying backend..."
    cd /opt/App/mern-todo-main
    docker build -t "$DOCKER_USERNAME/mern-todo-backend:v1" .
    docker push "$DOCKER_USERNAME/mern-todo-backend:v1"
    docker run -d --name backend \
        --network todo-network \
        -p 5100:5001 \
        -e MONGODB_URI=mongodb://mongodb:27017/mern-todo \
        "$DOCKER_USERNAME/mern-todo-backend:v1"

    # Deploy frontend
    log_info "Deploying frontend..."
    cd /opt/App/mern-todo-main/client
    docker build -t "$DOCKER_USERNAME/mern-todo-frontend:v1" .
    docker push "$DOCKER_USERNAME/mern-todo-frontend:v1"
    docker run -d --name frontend \
        --network todo-network \
        -p 3100:3000 \
        -e REACT_APP_API_URL=http://localhost:5100 \
        "$DOCKER_USERNAME/mern-todo-frontend:v1"

    # Health checks
    log_info "Performing health checks..."
    check_service_health "backend" 5100
    check_service_health "frontend" 3100

    # Final status check
    log_info "Checking final deployment status..."
    docker ps
    sudo systemctl status nginx

    log_info "Deployment completed successfully at $(date)"
    log_info "Application URLs:"
    log_info "- Via Nginx: http://localhost:8080"
    log_info "- Direct Frontend: http://localhost:3100"
    log_info "- Direct Backend: http://localhost:5100"
}

# Execute main function
main "$@"