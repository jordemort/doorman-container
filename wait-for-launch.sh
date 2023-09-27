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

if [ ! -e /mnt/doorman/DOOR.SYS ] ; then
  echo "ERROR: /mnt/doorman/DOOR.SYS does not exist" >&2
  exit 1
fi

if [ ! -e /mnt/door.lock ] ; then
  echo "ERROR: /mnt/door.lock does not exist" >&2
  exit 1
fi

echo "Aquiring shared lock on door..."

exec 99>/mnt/door.lock
if ! flock -sn 99 ; then
  echo "ERROR: Couldn't get shared lock on /mnt/door.lock" >&2
  exit 1
fi

if [ ! -e /mnt/node.lock ] ; then
  echo "ERROR: /mnt/node.lock does not exist" >&2
  exit 1
fi

echo "Aquiring exclusive lock on node..."

exec 98>/mnt/node.lock
if ! flock -w 60 -x 98 ; then
  echo "ERROR: Couldn't get exclusive lock on /mnt/node.lock" >&2
  exit 1
fi

cleanup() {
  rm -f /mnt/doorman/pts

  if [ -e /mnt/doorman/client.pid ] ; then
    client_pid=$(cat /mnt/doorman/client.pid)
    timeout 1 tail --pid="$client_pid" -f /dev/null || true
  fi

  qodem_pid=$(pidof qodem)
  if [ -n "$qodem_pid" ] ; then
    timeout 1 tail --pid="$qodem_pid" -f /dev/null || true
  fi

  tigervncserver -kill
}

trap cleanup EXIT
set -x

tigervncserver -geometry 720x480 -rfbunixpath=/mnt/doorman/vnc -SecurityTypes=None :0
export DISPLAY=:0

echo "Waiting for client..."
pts=$(timeout 60 socat UNIX-LISTEN:/mnt/doorman/pts - || true)
rm -f /mnt/doorman/pts

if [ -z "$pts" ] ; then
  echo "ERROR: Client never connected!" >&2
  exit 1
fi

cp ~/.dosemu/dosemurc /mnt/doorman/dosemurc
echo "\$_com1 = \"$pts pseudo\"" >> /mnt/doorman/dosemurc
echo "Starting dosemu2..."
dosemu -S -w -f /mnt/doorman/dosemurc -o /mnt/doorman/dos.log /mnt/doorman/DOORMAN.BAT
echo "dosemu2 exited"
