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

# Exclusion patterns
EXCLUDES=(
    "/Volumes/*"
    "/dev/*"
    "/proc/*"
    "/sys/*"
    "/tmp/*"
    "/run/*"
    "/mnt/*"
    "/media/*"
    "/lost+found"
    "/var/vm/*"
    "/var/tmp/*"
    "/private/var/vm/*"
    "/private/tmp/*"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".fseventsd"
    "node_modules"
    ".git"
    "*.swp"
    "*.tmp"
    "*~"
)

# Build exclude arguments
EXCLUDE_ARGS=""
for excl in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude=$excl"
done

# Backup command with link-dest if previous backup exists
if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP"
    rsync -aEAXHv --delete \
        --link-dest="$LATEST_BACKUP" \
        $EXCLUDE_ARGS \
        "$SOURCE" "$CURRENT_BACKUP"
else
    echo "Creating initial backup (no previous backup found)"
    rsync -aEAXHv --delete \
        $EXCLUDE_ARGS \
        "$SOURCE" "$CURRENT_BACKUP"
fi

echo "Backup completed successfully to: $CURRENT_BACKUP" 