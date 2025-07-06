#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

#
# Install required packages.
#
apk --no-cache add \
    build-base \
    wine-dev \

#
# Compile.
#
winegcc \
    -mconsole \
    -o /tmp/add_drive \
    "$SCRIPT_DIR"/add_drive.c
