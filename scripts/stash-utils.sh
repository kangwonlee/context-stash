#!/usr/bin/env bash
# stash-utils.sh — Shared utilities for the context-stash plugin
# Source this script for reusable helper functions.
#
# Usage: source "$(dirname "$0")/stash-utils.sh"

set -euo pipefail

STASH_DIR="${HOME}/.claude/stash"

# Create the stash directory with correct permissions if it doesn't exist.
# Fixes permissions if the directory exists but is misconfigured.
ensure_stash_dir() {
    if [ ! -d "$STASH_DIR" ]; then
        mkdir -p "$STASH_DIR"
        chmod 700 "$STASH_DIR"
        return 0
    fi

    local perms
    perms=$(get_perms "$STASH_DIR")
    if [ "$perms" != "700" ]; then
        echo "WARNING: Stash directory has permissions $perms (expected 700). Fixing..."
        chmod 700 "$STASH_DIR"
    fi
}

# Check that a stash file has owner-only permissions (600).
# Returns 0 if correct, 1 if not.
check_file_perms() {
    local file="$1"
    local perms
    perms=$(get_perms "$file")
    if [ "$perms" != "600" ]; then
        echo "WARNING: $file has permissions $perms (expected 600)"
        return 1
    fi
    return 0
}

# Get octal permissions for a file/directory.
# Handles both macOS (BSD stat) and Linux (GNU stat).
get_perms() {
    local path="$1"
    if stat -f "%Lp" "$path" >/dev/null 2>&1; then
        # macOS / BSD
        stat -f "%Lp" "$path"
    else
        # Linux / GNU
        stat -c "%a" "$path"
    fi
}

# Convert an ISO 8601 timestamp to a human-readable relative age.
# Example: "2 hours ago", "3 days ago", "45 days ago"
relative_age() {
    local timestamp="$1"
    local now
    now=$(date +%s)

    local then_epoch
    if date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%%[+-]*}" +%s >/dev/null 2>&1; then
        # macOS / BSD
        then_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${timestamp%%[+-]*}" +%s 2>/dev/null)
    else
        # Linux / GNU
        then_epoch=$(date -d "$timestamp" +%s 2>/dev/null)
    fi

    if [ -z "$then_epoch" ]; then
        echo "unknown age"
        return
    fi

    local diff=$(( now - then_epoch ))

    if [ "$diff" -lt 60 ]; then
        echo "just now"
    elif [ "$diff" -lt 3600 ]; then
        echo "$(( diff / 60 )) minutes ago"
    elif [ "$diff" -lt 86400 ]; then
        echo "$(( diff / 3600 )) hours ago"
    elif [ "$diff" -lt 604800 ]; then
        echo "$(( diff / 86400 )) days ago"
    elif [ "$diff" -lt 2592000 ]; then
        echo "$(( diff / 604800 )) weeks ago"
    else
        echo "$(( diff / 86400 )) days ago"
    fi
}

# Sanitize a stash name to lowercase alphanumeric + hyphens, max 40 chars.
sanitize_name() {
    local name="$1"
    echo "$name" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[^a-z0-9-]/-/g' \
        | sed 's/--*/-/g' \
        | sed 's/^-//' \
        | sed 's/-$//' \
        | cut -c1-40
}

# List all stash entry filenames (without path or .json extension).
list_stash_names() {
    if [ ! -d "$STASH_DIR" ]; then
        return
    fi
    for f in "$STASH_DIR"/*.json; do
        [ -f "$f" ] || continue
        basename "$f" .json
    done
}

# Count stash entries.
count_stash_entries() {
    local count=0
    if [ -d "$STASH_DIR" ]; then
        for f in "$STASH_DIR"/*.json; do
            [ -f "$f" ] && count=$(( count + 1 ))
        done
    fi
    echo "$count"
}
