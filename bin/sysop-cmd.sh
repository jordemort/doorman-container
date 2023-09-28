#!/usr/bin/env bash
set -euo pipefail

echo "Aquiring exclusive lock on door..."

exec 99>/mnt/door.lock
if ! flock -w 60 -x 99; then
  echo "ERROR: Couldn't get exclusive lock on /mnt/door.lock" >&2
  exit 1
fi

self=$(basename "$0")

if [ "$self" = "configure.sh" ]; then
  dosemu -t /mnt/doorman/DOORMAN.BAT
elif [ "$self" = "nightly.sh" ]; then
  dosemu -dumb /mnt/doorman/DOORMAN.BAT
else
  echo "ERROR: Not sure what to do as '$0'" >&2
  exit 1
fi
