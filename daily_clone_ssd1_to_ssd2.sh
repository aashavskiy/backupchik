#!/bin/bash

# daily_clone_ssd1_to_ssd2.sh
# Creates daily incremental backups from SSD1 to SSD2
# Uses hardlinks for efficient storage

# Exit on any error
set -e

# Source configuration files
source "var/paths.conf"

# Check if source and destination volumes are mounted
if [ ! -d "$SSD1_VOLUME" ]; then
    echo "Error: Source drive $SSD1_VOLUME is not mounted!"
    exit 1
fi

if [ ! -d "$SSD2_VOLUME" ]; then
    echo "Error: Destination drive $SSD2_VOLUME is not mounted!"
    exit 1
fi

TIMESTAMP=$(date +%Y-%m-%d)
CURRENT_BACKUP="$SSD1_DAILY_BACKUP_DIR/$TIMESTAMP"
LATEST_BACKUP=$(find "$SSD1_DAILY_BACKUP_DIR" -maxdepth 1 -type d | grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}$" | sort -r | head -n1)

# Create backup directory
sudo mkdir -p "$SSD1_DAILY_BACKUP_DIR"

# Check if exclude patterns file exists
EXCLUDE_FILE="exclude_patterns.txt"
if [ ! -f "$EXCLUDE_FILE" ]; then
    echo "Error: Exclude patterns file $EXCLUDE_FILE not found!"
    exit 1
fi

# Common rsync options
RSYNC_OPTS=(
    -aEAXHv        # archive, extended attrs, ACLs, xattrs, hardlinks, verbose
    --delete       # delete extraneous files from dest dirs
    --ignore-errors  # ignore errors
    --no-perms      # don't preserve permissions
    --chmod=u+rwX   # make files readable/writable by user
    --exclude-from="$EXCLUDE_FILE"  # use exclude patterns
)

# Create log file
LOG_FILE="$SSD1_DAILY_BACKUP_DIR/backup_${TIMESTAMP}.log"

echo "Starting backup at $(date)" | sudo tee -a "$LOG_FILE"
echo "Source: $SSD1_VOLUME" | sudo tee -a "$LOG_FILE"
echo "Destination: $CURRENT_BACKUP" | sudo tee -a "$LOG_FILE"
echo "Using exclude patterns from: $EXCLUDE_FILE" | sudo tee -a "$LOG_FILE"

if [ -n "$LATEST_BACKUP" ]; then
    echo "Creating incremental backup using hardlinks to: $LATEST_BACKUP" | sudo tee -a "$LOG_FILE"
    sudo rsync "${RSYNC_OPTS[@]}" --link-dest="$LATEST_BACKUP" "$SSD1_VOLUME/" "$CURRENT_BACKUP" 2>&1 | sudo tee -a "$LOG_FILE"
else
    echo "Creating initial backup (no previous backup found)" | sudo tee -a "$LOG_FILE"
    sudo rsync "${RSYNC_OPTS[@]}" "$SSD1_VOLUME/" "$CURRENT_BACKUP" 2>&1 | sudo tee -a "$LOG_FILE"
fi

echo "Backup completed at $(date)" | sudo tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE"

# Exit with success even if rsync returns code 23 (some files were not transferred)
if [ ${PIPESTATUS[0]} -eq 23 ]; then
    echo "Warning: Some files were not transferred (permissions/locked files)" | sudo tee -a "$LOG_FILE"
    exit 0
fi 