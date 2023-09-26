#!/usr/bin/env bash
set -euo pipefail

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
