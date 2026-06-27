#!/bin/bash
set -euo pipefail

MAX_WAIT=60
INTERVAL=2
ELAPSED=0

echo "Waiting for CrowdSec LAPI on :8080..."
while ! nc -z 172.19.0.1 8080 2>/dev/null; do
  if [ "$ELAPSED" -ge "$MAX_WAIT" ]; then
    echo "CrowdSec not ready after ${MAX_WAIT}s, starting anyway"
    break
  fi

  sleep "$INTERVAL"
  ELAPSED=$((ELAPSED + INTERVAL))
done

echo "CrowdSec ready after ${ELAPSED}s, starting Caddy..."
exec caddy docker-proxy --event-throttle-interval 3s
