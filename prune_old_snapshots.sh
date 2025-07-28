#!/bin/bash

# prune_old_snapshots.sh
# Removes old backup snapshots based on retention policy:
# - Hourly backups: older than 30 days
# - Daily backups: older than 90 days

# Exit on any error
set -e

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configurations
if [ -f "$SCRIPT_DIR/var/paths.conf" ]; then
    source "$SCRIPT_DIR/var/paths.conf"
else
    echo "Error: paths.conf not found in $SCRIPT_DIR/var"
    exit 1
fi

if [ -f "$SCRIPT_DIR/var/retention.conf" ]; then
    source "$SCRIPT_DIR/var/retention.conf"
else
    echo "Error: retention.conf not found in $SCRIPT_DIR/var"
    exit 1
fi

# Backup locations
HOURLY_BACKUP_ROOT="$MACBOOK_HOURLY_BACKUP_DIR"
DAILY_BACKUP_ROOT="$SSD1_DAILY_BACKUP_DIR"

# Function to safely remove old backups
remove_old_backups() {
    local backup_path="$1"
    local days="$2"
    local backup_type="$3"
    
    if [ ! -d "$backup_path" ]; then
        echo "Warning: Backup directory $backup_path not found or not mounted"
        return
    fi
    
    echo "Removing $backup_type backups older than $days days from $backup_path"
    
    # Find and remove old backups
    find "$backup_path" -maxdepth 1 -type d -mtime "+$days" | while read -r backup; do
        # Skip the root backup directory
        if [ "$backup" = "$backup_path" ]; then
            continue
        fi
        
        echo "Removing old backup: $backup"
        rm -rf "$backup"
    done
}

# Remove old hourly backups
remove_old_backups "$HOURLY_BACKUP_ROOT" "$HOURLY_RETENTION" "hourly"

# Remove old daily backups
remove_old_backups "$DAILY_BACKUP_ROOT" "$DAILY_RETENTION" "daily"

echo "Pruning completed successfully" 