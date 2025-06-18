#!/usr/bin/env bash
# Simple shell client for rjsonsrv
PORT=${1:-8080}
shift || true
CODE="$@"
if [ -z "$CODE" ]; then
  echo "Usage: rcli.sh [PORT] CODE" >&2
  exit 1
fi
curl -s -X POST -H "Content-Type: application/json" \
  -d "{\"command\": \"$CODE\"}" "http://127.0.0.1:$PORT/execute"
