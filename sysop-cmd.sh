#!/usr/bin/env bash
set -euo pipefail

# sanity checks

if [ ! -d /mnt/doorman ] ; then
  echo "ERROR: /mnt/doorman is not a directory" >&2
  exit 1
fi

if [ ! -d /mnt/door ] ; then
  echo "ERROR: /mnt/door is not a directory" >&2
  exit 1
fi

if [ ! -e /mnt/doorman/DOORMAN.BAT ] ; then
  echo "ERROR: /mnt/doorman/DOORMAN.BAT does not exist" >&2
  exit 1
fi

if [ ! -e /mnt/door.lock ] ; then
  echo "ERROR: /mnt/door.lock does not exist" >&2
  exit 1
fi

echo "Aquiring exclusive lock on door..."

exec 99>/mnt/door.lock
if ! flock -w 60 -x 99 ; then
  echo "ERROR: Couldn't get exclusive lock on /mnt/door.lock" >&2
  exit 1
fi

self=$(basename "$0")

if [ "$self" = "configure.sh" ] ; then
  dosemu -t /mnt/doorman/DOORMAN.BAT
elif [ "$self" = "nightly.sh" ] ; then
  dosemu -dumb /mnt/doorman/DOORMAN.BAT
else
  echo "ERROR: Not sure what to do as '$0'" >&2
  exit 1
fi
