#!/usr/bin/env bash
set -euo pipefail

SERVER_PID=""
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

random_port() {
  local candidate
  # Common default ports (Windows/macOS/Linux services) to avoid in the 3000-9000 range.
  local excluded_ports=(3000 3283 3306 3389 3689 3785 4045 5000 5432 5900 5901 6000 6379 6646 7000 7001 8000 8005 8009 8080 8443 8888 9000)
  while true; do
    candidate=$((RANDOM % (9000 - 3000 + 1) + 3000))
    if [[ ! " ${excluded_ports[*]} " =~ " ${candidate} " ]]; then
      echo "$candidate"
      return
    fi
  done
}

cleanup() {
  if [[ -n "$SERVER_PID" ]]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Starts the UDP server binary, sends it a test message, and prints the response.
run_udp_server_test() {
  local host="127.0.0.1"
  local port="$(random_port)"
  local msg="ECHO Testing UDP server"
  cd "$REPO_ROOT"
  zig build
  "$REPO_ROOT/zig-out/bin/lrc" udp-server "port=${port}" "address=${host}" &
  SERVER_PID=$!
  # Give the server a moment to bind before sending the test message.
  echo "BASH TEST -> Waiting for the server to start..."
  sleep 2.0
  echo "BASH TEST -> Sending test message to ${host}:${port}..."
  if command -v nc >/dev/null 2>&1; then
    local response
    response=$(echo -n "$msg" | nc -u -w 1 "$host" "$port")
    echo "BASH TEST -> Received: $response"
  else
    echo "BASH TEST -> nc (netcat) is required to send the UDP test message" >&2
    exit 1
  fi
}

run_udp_server_test
