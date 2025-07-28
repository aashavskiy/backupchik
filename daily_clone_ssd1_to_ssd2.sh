#!/bin/bash

# daily_clone_ssd1_to_ssd2.sh
# Creates daily incremental backups from SSD1 to SSD2
# Uses hardlinks for efficient storage

# Exit on any error
set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "Error: .env file not found in $SCRIPT_DIR"
    echo "Please copy .env.example to .env and configure your paths"
    exit 1
fi

# Base directories
SOURCE="$SSD1_VOLUME"
BACKUP_ROOT="$SSD1_DAILY_BACKUP_DIR"

# Create timestamp for current backup
TIMESTAMP=$(date +%Y-%m-%d)
CURRENT_BACKUP="$BACKUP_ROOT/$TIMESTAMP"

# Find the latest backup for hardlinking
LATEST_BACKUP=$(find "$BACKUP_ROOT" -maxdepth 1 -type d | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}$" | sort -r | head -n1)

# Check if source drive is mounted
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source drive $SOURCE is not mounted!"
    exit 1
fi

# Check if destination drive is mounted
if [ ! -d "$SSD2_VOLUME" ]; then
    echo "Error: Destination drive $SSD2_VOLUME is not mounted!"
    exit 1
fi

# Ensure backup root exists
mkdir -p "$BACKUP_ROOT"

# Backup command with link-dest if previous backup exists
if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP"
    rsync -aEAXHv --delete \
        --link-dest="$LATEST_BACKUP" \
        "$SOURCE/" "$CURRENT_BACKUP"
else
    echo "Creating initial backup (no previous backup found)"
    rsync -aEAXHv --delete \
        "$SOURCE/" "$CURRENT_BACKUP"
fi

echo "Backup completed successfully to: $CURRENT_BACKUP" 