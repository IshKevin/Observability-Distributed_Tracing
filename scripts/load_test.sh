#!/bin/bash
# Simulate realistic traffic and errors against the Flask app.
# Usage: ./scripts/load_test.sh [BASE_URL] [DURATION_SECONDS] [CONCURRENCY]
#
# Defaults: BASE_URL=http://localhost:5000  DURATION=120  CONCURRENCY=5

set -euo pipefail

BASE_URL="${1:-http://localhost:5000}"
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
      # 50% normal user listing
      curl -sf "$BASE_URL/api/users" -o /dev/null
    elif [ "$ROLL" -le 6 ]; then
      # 20% index
      curl -sf "$BASE_URL/" -o /dev/null
    elif [ "$ROLL" -eq 7 ]; then
      # 10% simulated error — drives error-rate alert
      curl -sf "$BASE_URL/api/simulate-error" -o /dev/null || true
    elif [ "$ROLL" -eq 8 ]; then
      # 10% high latency — drives latency alert
      DELAY=$(awk 'BEGIN { printf "%.2f", 0.3 + rand() * 0.5 }')
      curl -sf "$BASE_URL/api/simulate-latency?delay=$DELAY" -o /dev/null
    else
      # 10% external call
      curl -sf "$BASE_URL/api/external-call" -o /dev/null || true
    fi

    sleep 0.1
  done
}

# Launch background workers
PIDS=()
for i in $(seq 1 "$CONCURRENCY"); do
  _worker &
  PIDS+=($!)
done

# Progress bar
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
echo "==> Load test completed. Check Grafana at http://localhost:3000"
