#!/bin/bash

# hourly_backup.sh
# Creates incremental snapshots of MacBook to external SSD using rsync
# Uses hardlinks to previous backup for efficiency

# Exit on any error
set -e

# Source configuration files
source "var/paths.conf"

# Check if exclude patterns file exists
EXCLUDE_FILE="exclude_patterns.txt"
if [ ! -f "$EXCLUDE_FILE" ]; then
    echo "Error: Exclude patterns file $EXCLUDE_FILE not found!"
    exit 1
fi

# Check if source directory exists and is readable
if [ ! -d "$SOURCE_ROOT" ]; then
    echo "Error: Source directory $SOURCE_ROOT does not exist!"
    exit 1
fi

if [ ! -r "$SOURCE_ROOT" ]; then
    echo "Error: Source directory $SOURCE_ROOT is not readable!"
    exit 1
fi

# Check if destination volume is mounted and writable
if [ ! -d "$SSD1_VOLUME" ]; then
    echo "Error: Destination drive $SSD1_VOLUME is not mounted!"
    echo "Please connect the backup drive and try again."
    exit 1
fi

if [ ! -w "$SSD1_VOLUME" ]; then
    echo "Error: Destination drive $SSD1_VOLUME is not writable!"
    echo "Please check permissions and try again."
    exit 1
fi

# Create timestamp for current backup
TIMESTAMP=$(date +%Y-%m-%d_%H-%M)
CURRENT_BACKUP="$MACBOOK_HOURLY_BACKUP_DIR/$TIMESTAMP"

# Ensure backup directory exists and is writable
sudo mkdir -p "$MACBOOK_HOURLY_BACKUP_DIR"
if [ ! -w "$MACBOOK_HOURLY_BACKUP_DIR" ]; then
    echo "Error: Backup directory $MACBOOK_HOURLY_BACKUP_DIR is not writable!"
    echo "Please check permissions and try again."
    exit 1
fi

# Find the latest backup for hardlinking
LATEST_BACKUP=$(find "$MACBOOK_HOURLY_BACKUP_DIR" -maxdepth 1 -type d | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}$" | sort -r | head -n1)

# Create log file
LOG_FILE="$MACBOOK_HOURLY_BACKUP_DIR/backup_${TIMESTAMP}.log"

# Common rsync options
RSYNC_OPTS=(
    -aEAXHv        # archive, extended attrs, ACLs, xattrs, hardlinks, verbose
    --delete       # delete extraneous files from dest dirs
    --ignore-errors  # ignore errors
    --no-perms      # don't preserve permissions
    --chmod=u+rwX   # make files readable/writable by user
    --exclude-from="$EXCLUDE_FILE"  # use exclude patterns
)

echo "Starting backup at $(date)" | sudo tee -a "$LOG_FILE"
echo "Source: $SOURCE_ROOT" | sudo tee -a "$LOG_FILE"
echo "Destination: $CURRENT_BACKUP" | sudo tee -a "$LOG_FILE"
echo "Using exclude patterns from: $EXCLUDE_FILE" | sudo tee -a "$LOG_FILE"

if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP" | sudo tee -a "$LOG_FILE"
    sudo rsync "${RSYNC_OPTS[@]}" --link-dest="$LATEST_BACKUP" "$SOURCE_ROOT/" "$CURRENT_BACKUP" 2>&1 | sudo tee -a "$LOG_FILE"
else
    echo "Creating initial backup (no previous backup found)" | sudo tee -a "$LOG_FILE"
    sudo rsync "${RSYNC_OPTS[@]}" "$SOURCE_ROOT/" "$CURRENT_BACKUP" 2>&1 | sudo tee -a "$LOG_FILE"
fi

echo "Backup completed at $(date)" | sudo tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"

# Exit with success even if rsync returns code 23 (some files were not transferred)
if [ ${PIPESTATUS[0]} -eq 23 ]; then
    echo "Warning: Some files were not transferred (permissions/locked files)" | sudo tee -a "$LOG_FILE"
    exit 0
fi 