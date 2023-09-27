#!/usr/bin/env bash
set -euo pipefail

stty_sane() {
  stty sane
}

if [ "$TERM" != "ansi" ] && [ "$DOORMAN_RAW" != "1" ]; then
  if [ -z "${IN_QODEM:-}" ]; then
    trap stty_sane EXIT
    IN_QODEM=1 qodem \
      -x \
      --read-only \
      --codepage CP437 \
      --emulation ansi \
      --status-line off \
      "$0"
    exit "$?"
  fi
fi

echo $$ >/mnt/doorman/client.pid
echo "Waiting for door to start..."

timeout 60 wait-for-pts.sh || true
if [ ! -e /mnt/doorman/pts ]; then
  echo "ERROR: Timed out waiting for /mnt/doorman/pts" >&2
  exit 1
fi

tty | socat - UNIX-CONNECT:/mnt/doorman/pts

dosemu_pid=$(timeout 60 pidof-dosemu.sh || true)
if [ -z "$dosemu_pid" ]; then
  echo "dosemu never started?" >&2
  exit 1
fi

tail --pid="$dosemu_pid" -f /dev/null
