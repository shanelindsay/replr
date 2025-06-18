#!/usr/bin/env bash
#
# Very small CLI for the R JSON server described earlier.

CONFIG_DIR="${HOME}/.rjson"
INST_FILE="${CONFIG_DIR}/instances"
DEFAULT_PORT=8080

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
    echo "$label"
  fi
}

case "$1" in
  start)
    label=${2:-default}
    port=${3:-$DEFAULT_PORT}
    Rscript r_json_server.R --background --port "$port" &
    pid=$!
    echo "${label}:${port}:${pid}" >> "${INST_FILE}"
    echo "Started '${label}' on port ${port} (PID ${pid})"
    ;;

  stop)
    label=${2:-default}
    port=$(port_of "$label")
    curl -s -X POST "http://127.0.0.1:${port}/shutdown" >/dev/null
    sed -i.bak "/^${label}:/d" "${INST_FILE}"
    echo "Sent shutdown to '${label}' (port ${port})"
    ;;

  status)
    label=${2:-default}
    port=$(port_of "$label")
    curl -s "http://127.0.0.1:${port}/status" | jq
    ;;

  exec)
    label=${2:-default}
    port=$(port_of "$label")
    code=""
    if [[ -t 0 ]] && [[ -z $3 ]]; then
      echo "Nothing to run; supply code with -e or pipe via stdin" >&2
      exit 1
    fi
    while [[ $# -gt 2 ]]; do shift; [[ $1 == -e ]] && { code="$2"; shift; } done
    [[ -z $code ]] && code=$(cat)       # read piped input
    curl -s -X POST -H "Content-Type: application/json" \
         -d "{\"command\":$(jq -Rs . <<<"$code")}" \
         "http://127.0.0.1:${port}/execute" | jq
    ;;

  list)
    cat "${INST_FILE}"
    ;;

  *)
    cat <<EOF
Usage: rcli.sh {start [label] [port]|stop [label]|status [label]|exec [label] -e CODE|exec [label] < script.R|list}
EOF
    ;;
esac
