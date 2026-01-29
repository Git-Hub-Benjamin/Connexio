#!/bin/bash
# Connexio Launcher Script for Linux
# Place this in /usr/local/bin/ or add to PATH

CONNEXIO_PATH="${CONNEXIO_PATH:-/opt/connexio/connexio}"

if [ -f "$CONNEXIO_PATH" ]; then
    exec "$CONNEXIO_PATH" "$@"
elif [ -f "./build/linux/x64/release/bundle/connexio" ]; then
    exec "./build/linux/x64/release/bundle/connexio" "$@"
else
    echo "Connexio not found. Please build first with ./setup.sh"
    exit 1
fi
