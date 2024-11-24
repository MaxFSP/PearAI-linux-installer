#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

handle_error() {
    log "Error: $1"
    echo "Error: $1" >&2
    exit 1
}

check_file_exists() {
    if [ ! -f "$1" ]; then
        handle_error "$1 not found"
    fi
}
