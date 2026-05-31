#!/bin/bash
set -e

echo "🚀 Deploying Music Platform..."

# متغیرها — اینا رو عوض کن
SERVER_IP="YOUR_VPS_IP"
SERVER_USER="root"
DEPLOY_PATH="/opt/music-platform"

echo "📦 Building API..."
cd apps/api && pnpm build && cd ../..

echo "📤 Uploading to server..."
rsync -avz --exclude node_modules \
  --exclude .git \
  --exclude "apps/mobile" \
  --exclude "apps/web" \
  . ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}

echo "🔄 Restarting services..."
ssh ${SERVER_USER}@${SERVER_IP} "
  cd ${DEPLOY_PATH}
  docker compose -f docker-compose.production.yml up -d --build
  docker compose -f docker-compose.production.yml ps
"

echo "✅ Deploy complete!"
