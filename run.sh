#!/bin/bash
# StoneAge Server Startup Script
# Logs are GBK internally, piped through iconv for UTF-8 terminal display

SAAC_DIR="$(cd "$(dirname "$0")/saac" && pwd)"
GMSV_DIR="$(cd "$(dirname "$0")/gmsv" && pwd)"
LOG_DIR="$GMSV_DIR/logs"
mkdir -p "$LOG_DIR"

echo "=== Starting SAAC (Account Server) ==="
cd "$SAAC_DIR"
./saac 2>&1 | iconv -f gbk -t utf-8 2>/dev/null | tee "$LOG_DIR/saac.log" &
SAAC_PID=$!

sleep 1

echo "=== Starting GMSV (Game Server) ==="
cd "$GMSV_DIR"
./gmsv 2>&1 | iconv -f gbk -t utf-8 2>/dev/null | tee "$LOG_DIR/gmsv.log" &
GMSV_PID=$!

echo "SAAC PID: $SAAC_PID"
echo "GMSV PID: $GMSV_PID"
echo "Logs: $LOG_DIR/saac.log, $LOG_DIR/gmsv.log"

trap "kill $SAAC_PID $GMSV_PID 2>/dev/null; exit" INT TERM
wait
