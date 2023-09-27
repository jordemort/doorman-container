#!/usr/bin/env bash
set -euo pipefail

if [ "$TERM" != "ansi" ] && [ "$DOORMAN_RAW" != "1" ] ; then
  if [ -z "${IN_QODEM:-}" ] ; then
    IN_QODEM=1 exec qodem \
      -x \
      --read-only \
      --codepage CP437 \
      --emulation ansi \
      --status-line off \
      "$0"
  fi
fi

echo $$ > /mnt/doorman/client.pid
echo "Waiting for door to start..."

while [ ! -e /mnt/doorman/pts ] ; do
  sleep 0.1
done

tty | socat - UNIX-CONNECT:/mnt/doorman/pts

while [ -z "$(pidof dosemu.bin)" ] ; do
  sleep 0.1
done

tail --pid="$(pidof dosemu.bin)" -f /dev/null
