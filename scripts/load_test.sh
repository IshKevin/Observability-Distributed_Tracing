#!/bin/bash

set -euo pipefail

BASE_URL="${1:-http://44.201.56.163:5000}"
DURATION="${2:-120}"
CONCURRENCY="${3:-5}"

END=$((SECONDS + DURATION))

echo "==> Load test started"
echo "    Target     : $BASE_URL"
echo "    Duration   : ${DURATION}s"
echo "    Concurrency: $CONCURRENCY parallel loops"
echo ""

_worker() {
  while [ $SECONDS -lt $END ]; do
    ROLL=$((RANDOM % 10))

    if   [ "$ROLL" -le 4 ]; then
      curl -sf "$BASE_URL/api/users" -o /dev/null
    elif [ "$ROLL" -le 6 ]; then
      curl -sf "$BASE_URL/" -o /dev/null
    elif [ "$ROLL" -eq 7 ]; then
      curl -sf "$BASE_URL/api/simulate-error" -o /dev/null || true
    elif [ "$ROLL" -eq 8 ]; then
      DELAY=$(awk 'BEGIN { printf "%.2f", 0.3 + rand() * 0.5 }')
      curl -sf "$BASE_URL/api/simulate-latency?delay=$DELAY" -o /dev/null
    else
      curl -sf "$BASE_URL/api/external-call" -o /dev/null || true
    fi

    sleep 0.1
  done
}

PIDS=()
for i in $(seq 1 "$CONCURRENCY"); do
  _worker &
  PIDS+=($!)
done


while [ $SECONDS -lt $END ]; do
  REMAINING=$((END - SECONDS))
  ELAPSED=$((DURATION - REMAINING))
  PCT=$((ELAPSED * 100 / DURATION))
  printf "\r    Progress: [%-50s] %3d%% (%ds remaining)" \
    "$(printf '#%.0s' $(seq 1 $((PCT / 2))))" "$PCT" "$REMAINING"
  sleep 1
done

# Wait for workers
for PID in "${PIDS[@]}"; do wait "$PID" 2>/dev/null || true; done

echo ""
echo ""
echo "==> Load test completed. Check Grafana at http://44.201.56.163:3000"
