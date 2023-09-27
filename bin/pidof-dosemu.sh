#!/usr/bin/env bash
set -euo pipefail

dosemu_pid=$(pidof dosemu.bin || true)

while [ -z "$dosemu_pid" ]; do
  sleep 0.1
  dosemu_pid=$(pidof dosemu.bin || true)
done

echo "$dosemu_pid"
