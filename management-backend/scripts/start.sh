#!/bin/bash

# ZeroSpoils Management Backend Startup Script
# Starts the complete local runtime: API, Worker, Frontend, Redis

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🍽️  ZeroSpoils Management Backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose."
    exit 1
fi

echo "✅ Docker and Docker Compose found"
echo ""

# Check if containers are already running
if [ "$(docker ps -q -f name=zerospoils-mgmt)" ]; then
    echo "⚠️  Some containers are already running."
    read -p "Stop and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🛑 Stopping existing containers..."
        docker-compose -f "$ROOT_DIR/docker-compose.yml" down
    else
        echo "ℹ️  Containers are already running at:"
        echo "   Frontend:  http://localhost:3000"
        echo "   API:       http://localhost:3001"
        echo "   Worker:    http://localhost:3002"
        exit 0
    fi
fi

echo "🚀 Starting ZeroSpoils Management Backend..."
echo ""

cd "$ROOT_DIR"

# Start services
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check health
for i in {1..30}; do
    if curl -s http://localhost:3001/health > /dev/null 2>&1; then
        echo "✅ API is healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ API did not become healthy"
        exit 1
    fi
    echo "⏳ Checking API health ($i/30)..."
    sleep 1
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All services started successfully!"
echo ""
echo "📊 Management Dashboard:"
echo "   🌐 http://localhost:3000"
echo ""
echo "🔑 Test Accounts:"
echo "   • admin@zerospoils.local (full access)"
echo "   • analyst@zerospoils.local (read metrics/telemetry)"
echo "   • support@zerospoils.local (feedback triage only)"
echo ""
echo "📚 API Documentation:"
echo "   📖 http://localhost:3001/status"
echo "   📖 docs/LOCAL_RUNTIME.md"
echo ""
echo "🔧 Useful Commands:"
echo "   docker-compose logs -f                # Watch all logs"
echo "   docker-compose logs -f api            # Watch API logs"
echo "   docker-compose ps                     # Service status"
echo "   docker-compose down                   # Stop all services"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
