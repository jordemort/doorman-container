#!/usr/bin/env bash
set -euo pipefail

# sanity checks

if [ ! -d /mnt/doorman ]; then
  echo "ERROR: /mnt/doorman is not a directory" >&2
  exit 1
fi

if [ ! -d /mnt/door ]; then
  echo "ERROR: /mnt/door is not a directory" >&2
  exit 1
fi

if [ ! -e /mnt/doorman/DOORMAN.BAT ]; then
  echo "ERROR: /mnt/doorman/DOORMAN.BAT does not exist" >&2
  exit 1
fi

if [ ! -e /mnt/doorman/DOOR.SYS ]; then
  echo "ERROR: /mnt/doorman/DOOR.SYS does not exist" >&2
  exit 1
fi

if [ ! -e /mnt/door.lock ]; then
  echo "ERROR: /mnt/door.lock does not exist" >&2
  exit 1
fi

echo "Aquiring shared lock on door..."

exec 99>/mnt/door.lock
if ! flock -sn 99; then
  echo "ERROR: Couldn't get shared lock on /mnt/door.lock" >&2
  exit 1
fi

if [ ! -e /mnt/node.lock ]; then
  echo "ERROR: /mnt/node.lock does not exist" >&2
  exit 1
fi

echo "Aquiring exclusive lock on node..."

exec 98>/mnt/node.lock
if ! flock -w 60 -x 98; then
  echo "ERROR: Couldn't get exclusive lock on /mnt/node.lock" >&2
  exit 1
fi

cleanup() {
  rm -f /mnt/doorman/pts

  if [ -e /mnt/doorman/client.pid ]; then
    client_pid=$(cat /mnt/doorman/client.pid)
    timeout 1 tail --pid="$client_pid" -f /dev/null || true
  fi

  qodem_pid=$(pidof qodem)
  if [ -n "$qodem_pid" ]; then
    timeout 1 tail --pid="$qodem_pid" -f /dev/null || true
  fi
}

trap cleanup EXIT

echo "Waiting for client..."
pts=$(timeout 60 socat UNIX-LISTEN:/mnt/doorman/pts - || true)
rm -f /mnt/doorman/pts

if [ -z "$pts" ]; then
  echo "ERROR: Client never connected!" >&2
  exit 1
fi

cp ~/.dosemu/dosemurc /mnt/doorman/dosemurc
echo "\$_com1 = \"$pts pseudo\"" >>/mnt/doorman/dosemurc
echo "Starting dosemu..."
tmux -S /mnt/doorman/tmux -S /mnt/doorman/tmux new-session -s dosemu -d -- \
  dosemu -t -f /mnt/doorman/dosemurc -o /mnt/doorman/dos.log /mnt/doorman/DOORMAN.BAT \; \
  set window-size manual

dosemu_pid=$(timeout 60 pidof-dosemu.sh || true)
if [ -z "$dosemu_pid" ]; then
  echo "dosemu never started?" >&2
  exit 1
fi

echo "dosemu running with pid $dosemu_pid"
tail --pid="$dosemu_pid" -f /dev/null
echo "dosemu exited"
