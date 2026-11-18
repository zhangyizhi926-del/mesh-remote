#!/usr/bin/env bash
set -Eeuo pipefail

CONFIG="/etc/mesh-remote/quota.conf"
STATE_DIR="/var/lib/mesh-remote-quota"
STOP_FILE="$STATE_DIR/stopped"
RELAY="mesh-remote-relay.service"

if [[ -f "$STOP_FILE" ]]; then
  systemctl stop "$RELAY"
  exit 0
fi

BASELINE_MONTH=""
BASELINE_TX_BYTES=0
# This configuration is installed and edited by root.
source "$CONFIG"
[[ "${IFACE:-}" =~ ^[A-Za-z0-9_.:-]+$ ]] || { echo "Invalid IFACE." >&2; exit 2; }
for value in "${WARN_BYTES:-}" "${STOP_BYTES:-}" "$BASELINE_TX_BYTES"; do
  [[ "$value" =~ ^(0|[1-9][0-9]{0,14})$ ]] || { echo "Invalid byte threshold or baseline." >&2; exit 2; }
done
(( WARN_BYTES > 0 && STOP_BYTES > WARN_BYTES )) || { echo "Require 0 < WARN_BYTES < STOP_BYTES." >&2; exit 2; }
[[ -z "$BASELINE_MONTH" || "$BASELINE_MONTH" =~ ^[0-9]{4}-(0[1-9]|1[0-2])$ ]] ||
  { echo "Use YYYY-MM for BASELINE_MONTH." >&2; exit 2; }

month="$(date +%Y-%m)"
year="${month%-*}"
month_number="$((10#${month#*-}))"
json="$(vnstat -i "$IFACE" --json m)"
tx="$(jq -er --arg iface "$IFACE" --argjson year "$year" --argjson month "$month_number" '
  .interfaces[] | select(.name == $iface) |
  if (.traffic.month | type) != "array" then error("Missing monthly counters") else
    [.traffic.month[] | select(.date.year == $year and .date.month == $month) | .tx]
    | if any(.[]; type != "number") then error("Invalid TX counter") else add // 0 end
  end
' <<<"$json")"
[[ "$tx" =~ ^(0|[1-9][0-9]{0,14})$ ]] || { echo "Invalid TX counter." >&2; exit 2; }
if [[ "$BASELINE_MONTH" == "$month" ]]; then
  tx=$((tx + BASELINE_TX_BYTES))
fi

printf 'month=%s interface=%s tx_bytes=%s\n' "$month" "$IFACE" "$tx"
if (( tx >= STOP_BYTES )); then
  printf 'month=%s tx_bytes=%s\n' "$month" "$tx" >"$STOP_FILE"
  systemctl stop "$RELAY"
  printf 'Stopped %s at %s bytes (limit %s).\n' "$RELAY" "$tx" "$STOP_BYTES"
elif (( tx >= WARN_BYTES )) && [[ ! -e "$STATE_DIR/warned-$month" ]]; then
  printf 'Relay traffic warning at %s bytes (threshold %s).\n' "$tx" "$WARN_BYTES"
  touch "$STATE_DIR/warned-$month"
fi
