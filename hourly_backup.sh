#!/bin/bash

# hourly_backup.sh
# Creates incremental snapshots of MacBook to external SSD using rsync
# Uses hardlinks to previous backup for efficiency

# Exit on any error
set -e

# Base directories
BACKUP_ROOT="/Volumes/SSD1/Backups/MacBook/hourly"
SOURCE="/"

# Create timestamp for current backup
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
CURRENT_BACKUP="$BACKUP_ROOT/$TIMESTAMP"

# Find the latest backup for hardlinking
LATEST_BACKUP=$(find "$BACKUP_ROOT" -maxdepth 1 -type d | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$" | sort -r | head -n1)

# Ensure backup root exists
mkdir -p "$BACKUP_ROOT"

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXCLUDE_FILE="$SCRIPT_DIR/exclude_patterns.txt"

# Check if exclude file exists
if [ ! -f "$EXCLUDE_FILE" ]; then
    echo "Error: Exclude patterns file not found at: $EXCLUDE_FILE"
    exit 1
fi

# Backup command with link-dest if previous backup exists
if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP"
    rsync -aEAXHv --delete \
        --exclude-from="$EXCLUDE_FILE" \
        --link-dest="$LATEST_BACKUP" \
        "$SOURCE" "$CURRENT_BACKUP"
else
    echo "Creating initial backup (no previous backup found)"
    rsync -aEAXHv --delete \
        --exclude-from="$EXCLUDE_FILE" \
        "$SOURCE" "$CURRENT_BACKUP"
fi

echo "Backup completed successfully to: $CURRENT_BACKUP" 