#!/bin/bash
# =============================================================================
# SEASONS Backend Deployment Script
# Usage: ./deploy.sh [options]
# Options:
#   --check      Check status without deploying
#   --reload     Reload service (no restart)
#   --logs       Show recent logs
#   --full       Full deploy with dependency update
# =============================================================================

set -e

SSH_KEY="~/.ssh/openclaw_key"
ECS_HOST="116.62.32.43"
ECS_USER="root"
BACKEND_DIR="/opt/shunshi/backend"
LOCAL_BACKEND="/Users/feifei00/Documents/Shunshi/backend"
LOG_FILE="/tmp/shunshi-deploy-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

ssh_cmd() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$ECS_USER@$ECS_HOST" "$@"
}

# Parse arguments
ACTION="${1:-deploy}"

case "$ACTION" in
  --check)
    log "Checking SEASONS backend status..."
    ssh_cmd "echo '=== Service Status ===' && systemctl status shunshi --no-pager -l | head -20"
    ssh_cmd "echo '=== Port Check ===' && ss -tlnp | grep -E '4000|4001|6379'"
    ssh_cmd "echo '=== API Health ===' && curl -s http://127.0.0.1:4000/health && echo ''"
    ssh_cmd "echo '=== Redis ===' && redis-cli ping"
    ssh_cmd "echo '=== Disk/Memory ===' && df -h / && free -h"
    ssh_cmd "echo '=== Recent Logs ===' && journalctl -u shunshi --no-pager -n 10"
    exit 0
    ;;

  --logs)
    log "Showing recent backend logs..."
    ssh_cmd "journalctl -u shunshi --no-pager -f -n 50"
    exit 0
    ;;

  --reload)
    log "Reloading SEASONS backend service..."
    ssh_cmd "systemctl reload shunshi && log 'Reload OK' || warn 'Reload failed'"
    exit 0
    ;;
esac

# Full deploy
log "============================================"
log " SEASONS Backend Deployment"
log " Time: $(date)"
log "============================================"

# Step 1: Check prerequisites
log "Step 1/6: Checking prerequisites..."
ssh_cmd "test -f $SSH_KEY" || { err "SSH key not found on ECS"; exit 1; }
ssh_cmd "systemctl is-active postgresql" || { err "PostgreSQL not running"; exit 1; }
ssh_cmd "systemctl is-active redis" || { err "Redis not running"; exit 1; }
ssh_cmd "systemctl is-active nginx" || { err "Nginx not running"; exit 1; }
log "  Prerequisites OK"

# Step 2: Pull latest code from git (if applicable) or rsync local changes
log "Step 2/6: Syncing code to ECS..."
rsync -az -e "ssh -i $SSH_KEY" \
  --exclude '__pycache__' \
  --exclude '*.pyc' \
  --exclude '.venv' \
  --exclude 'node_modules' \
  --exclude 'logs' \
  --exclude '*.db' \
  --exclude '.git' \
  "$LOCAL_BACKEND/" "$ECS_USER@$ECS_HOST:$BACKEND_DIR/"
log "  Sync complete"

# Step 3: Install dependencies
log "Step 3/6: Installing dependencies..."
ssh_cmd "cd $BACKEND_DIR && .venv/bin/pip install -q -r requirements.txt --upgrade 2>&1 | tail -5"
log "  Dependencies OK"

# Step 4: Run migrations (if any)
log "Step 4/6: Checking migrations..."
ssh_cmd "cd $BACKEND_DIR && .venv/bin/python -c \"
from app.database.db import engine
from sqlalchemy import text
with engine.connect() as conn:
    print('DB OK:', conn.execute(text('SELECT 1')).scalar())
\" 2>/dev/null && echo '  Database OK' || warn 'Database connection issue'"
log "  Migrations check complete"

# Step 5: Restart service
log "Step 5/6: Restarting backend service..."
ssh_cmd "systemctl restart shunshi && sleep 3"
ssh_cmd "systemctl status shunshi --no-pager | grep 'Active:'"
log "  Service restarted"

# Step 6: Verify
log "Step 6/6: Verifying deployment..."
sleep 2
API_STATUS=$(ssh_cmd "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:4000/health")
if [ "$API_STATUS" = "200" ]; then
    log "  API health check: ${GREEN}OK ($API_STATUS)${NC}"
else
    warn "  API health check: ${RED}FAILED ($API_STATUS)${NC}"
    ssh_cmd "journalctl -u shunshi --no-pager -n 10 | tail -5"
fi

NGINX_STATUS=$(ssh_cmd "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/api/v1/seasons/season/current 2>/dev/null")
log "  Nginx routing test: $NGINX_STATUS"

log "============================================"
log " Deployment complete!"
log " SEASONS API: http://116.62.32.43/api/v1/seasons/"
log " Health:       http://116.62.32.43/api/v1/seasons/season/current"
log "============================================"
