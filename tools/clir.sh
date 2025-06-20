#!/usr/bin/env bash
#
# Very small CLI for the R JSON server described earlier.

# Ensure jq is available for JSON encoding
if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but was not found in PATH." >&2
  exit 1
fi

CONFIG_DIR="${HOME}/.replr"
INST_FILE="${CONFIG_DIR}/instances"
DEFAULT_PORT=8080
DEFAULT_HOST="127.0.0.1"

mkdir -p "${CONFIG_DIR}"
touch  "${INST_FILE}"

# ----------------------------------------------------------
# Helper: lookup port from label (else treat as raw port)
port_of() {
  local label=$1
  local line
  line=$(grep "^${label}:" "${INST_FILE}" 2>/dev/null)
  if [[ -n $line ]]; then
    cut -d':' -f2 <<<"$line"
  else
    if [[ $label =~ ^[0-9]+$ ]]; then
      echo "$label"
    else
      echo "$DEFAULT_PORT"
    fi
  fi
}

start_instance() {
  local label=$1
  local port=$2
  local host=$3
  local script_dir="$(cd "$(dirname "$0")" && pwd)"
  local script="$script_dir/../inst/scripts/replr_server.R"
  mkdir -p "$label"
  REPLR_BASE_DIR="$label" Rscript "$script" --background --port "$port" --host "$host" >/dev/null 2>&1 &
  local pid=$!
  echo "${label}:${port}:${pid}" >> "${INST_FILE}"
  echo "Started '${label}' on ${host}:${port} (PID ${pid})" >&2
}

case "$1" in
  start)
    label=${2:-default}
    port=${3:-$DEFAULT_PORT}
    host=${4:-$DEFAULT_HOST}
    start_instance "$label" "$port" "$host"
    ;;

  stop)
    label=${2:-default}
    host=${3:-$DEFAULT_HOST}
    port=$(port_of "$label")
    curl -s -X POST "http://${host}:${port}/shutdown" >/dev/null
    sed -i.bak "/^${label}:/d" "${INST_FILE}"
    echo "Sent shutdown to '${label}' on ${host} (port ${port})"
    ;;

  status)
    label=${2:-default}
    host=${3:-$DEFAULT_HOST}
    port=$(port_of "$label")
    curl -s "http://${host}:${port}/status"
    ;;

  state)
    label=${2:-default}
    host=${3:-$DEFAULT_HOST}
    port=$(port_of "$label")
    curl -s "http://${host}:${port}/state"
    ;;

  exec)
    label=${2:-default}
    port=$(port_of "$label")
    code=""
    json=0
    host="$DEFAULT_HOST"
    if [[ -t 0 ]] && [[ -z $3 ]]; then
      echo "Nothing to run; supply code with -e or pipe via stdin" >&2
      exit 1
    fi
    shift 2
    while [[ $# -gt 0 ]]; do
      case "$1" in
        -e)
          code="$2"; shift 2;;
        --json|-j)
          json=1; shift;;
        *)
          host="$1"; shift;;
      esac
    done
    [[ -z $code ]] && code=$(cat)
    if ! curl -s "http://${host}:${port}/status" >/dev/null; then
      echo "Initializing server for '${label}' on ${host} port ${port}..." >&2
      start_instance "$label" "$port" "$host"
      sleep 1
    fi
    url="http://${host}:${port}/execute"
    if [[ $json -eq 0 ]]; then
      url="${url}?format=text"
    else
      url="${url}?plain=false"
    fi
    curl -s -X POST -H "Content-Type: application/json" \
         -d "{\"command\":$(jq -Rs . <<<"$code")}" \
         "$url"

    ;;

  list)
    cat "${INST_FILE}"
    ;;

  *)
    cat <<EOF
Usage: clir.sh {start [label] [port] [host]|stop [label] [host]|status [label] [host]|state [label] [host]|exec [label] [-e CODE] [--json] [host]|list}

When '--json' is supplied to 'exec', the server responds with
a JSON object containing: output, warning, error, plots,
result_summary and result.
EOF
    ;;
esac
