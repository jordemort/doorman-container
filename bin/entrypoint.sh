#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "HEY LISTEN! This container image isn't meant to be used directy!" >&2
  echo "Please install \`doorman\`: https://github.com/jordemort/doorman" >&2
  exit 1
}

usage_error() {
  echo "ERROR: $1" >&2
  usage
}

if [ -z "${DOORMAN_SKIP_SANITY_CHECKS:-}" ]; then
  if [ ! -d /mnt/doorman ]; then
    usage_error "/mnt/doorman is not a directory"
  fi

  if [ ! -d /mnt/door ]; then
    usage_error "/mnt/door is not a directory"
  fi

  if [ ! -e /mnt/doorman/DOORMAN.BAT ]; then
    usage_error "/mnt/doorman/DOORMAN.BAT does not exist"
  fi

  if [ ! -e /mnt/door.lock ]; then
    usage_error "/mnt/door.lock does not exist"
  fi

  if [ "$#" -lt 1 ]; then
    usage
  fi
fi

export LOGNAME=doorman
export USER=doorman
export HOME=/home/doorman

exec "$@"
