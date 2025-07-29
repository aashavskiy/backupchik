#!/bin/bash

# hourly_backup.sh
# Creates incremental snapshots of MacBook to external SSD using rsync
# Uses hardlinks to previous backup for efficiency

# Exit on any error
set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
if [ -f "$SCRIPT_DIR/var/paths.conf" ]; then
    source "$SCRIPT_DIR/var/paths.conf"
else
    echo "Error: paths.conf not found in $SCRIPT_DIR/var"
    exit 1
fi

# Base directories
BACKUP_ROOT="$MACBOOK_HOURLY_BACKUP_DIR"
SOURCE="$SOURCE_ROOT"

# Create timestamp for current backup
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
CURRENT_BACKUP="$BACKUP_ROOT/$TIMESTAMP"
LOG_FILE="$BACKUP_ROOT/backup_${TIMESTAMP}.log"

# Find the latest backup for hardlinking
LATEST_BACKUP=$(find "$BACKUP_ROOT" -maxdepth 1 -type d | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$" | sort -r | head -n1)

# Check if source drive is mounted
if [ ! -d "$SOURCE" ]; then
    echo "Error: Source directory $SOURCE is not accessible!"
    exit 1
fi

# Check if destination drive is mounted
if [ ! -d "$(dirname "$BACKUP_ROOT")" ]; then
    echo "Error: Destination drive $(dirname "$BACKUP_ROOT") is not mounted!"
    exit 1
fi

# Ensure backup root exists
mkdir -p "$BACKUP_ROOT"

# Get exclude file path
EXCLUDE_FILE="$SCRIPT_DIR/exclude_patterns.txt"

# Check if exclude file exists
if [ ! -f "$EXCLUDE_FILE" ]; then
    echo "Error: Exclude patterns file not found at: $EXCLUDE_FILE"
    exit 1
fi

# Common rsync options
RSYNC_OPTS=(
    -aEAXHv        # archive, extended attrs, ACLs, xattrs, hardlinks, verbose
    --delete       # delete extraneous files from dest dirs
    --exclude-from="$EXCLUDE_FILE"  # exclude patterns
    --ignore-errors  # ignore errors
    --no-perms      # don't preserve permissions
    --chmod=u+rwX   # make files readable/writable by user
    --log-file="$LOG_FILE"  # log all actions
)

echo "Starting backup at $(date)" | tee -a "$LOG_FILE"
echo "Source: $SOURCE" | tee -a "$LOG_FILE"
echo "Destination: $CURRENT_BACKUP" | tee -a "$LOG_FILE"
echo "Exclude patterns from: $EXCLUDE_FILE" | tee -a "$LOG_FILE"

# Backup command with link-dest if previous backup exists
if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP" | tee -a "$LOG_FILE"
    rsync "${RSYNC_OPTS[@]}" \
        --link-dest="$LATEST_BACKUP" \
        "$SOURCE/" "$CURRENT_BACKUP"
else
    echo "Creating initial backup (no previous backup found)" | tee -a "$LOG_FILE"
    rsync "${RSYNC_OPTS[@]}" \
        "$SOURCE/" "$CURRENT_BACKUP"
fi

echo "Backup completed at $(date)" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"

# Even if some files were not copied (exit code 23), consider backup successful
if [ $? -eq 23 ]; then
    echo "Warning: Some files were not transferred (permissions/locked files)" | tee -a "$LOG_FILE"
    exit 0
fi 