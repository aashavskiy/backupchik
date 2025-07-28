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
    # System directories and files
    "/Volumes/*"          # External drives
    "/dev/*"             # Device files
    "/proc/*"            # Process information
    "/sys/*"             # System files
    "/tmp/*"             # Temporary files
    "/run/*"             # Runtime files
    "/mnt/*"             # Mount points
    "/media/*"           # Media mounts
    "/lost+found"        # File system recovery
    "/var/vm/*"          # Virtual memory files
    "/var/tmp/*"         # Temporary files
    "/private/var/vm/*"  # macOS virtual memory
    "/private/tmp/*"     # macOS temporary files
    
    # macOS specific
    ".Spotlight-V100"    # Spotlight index
    ".TemporaryItems"    # Temporary items
    ".Trashes"          # Trash folders
    ".fseventsd"        # File system events
    ".DS_Store"         # Finder settings files
    
    # Development and build files
    "node_modules"      # NPM packages
    ".git"             # Git repositories
    "target/"          # Maven/Rust build directory
    "build/"           # Generic build directory
    "dist/"           # Distribution directory
    "*.swp"           # Vim swap files
    "*.tmp"           # Temporary files
    "*~"              # Backup files
    
    # Add your custom exclusions here
    "*/Downloads"      # Downloads folder
    "*/Library/Caches" # Application caches
    "*/Library/Application Support/Steam" # Steam games
    "*/Library/Containers"  # App containers
    "*/Movies"         # Movies folder (optional)
    
    # Browser caches
    "*/Library/Caches/Google/Chrome"
    "*/Library/Application Support/Google/Chrome/Default/Cache"
    "*/Library/Caches/Firefox"
    "*/Library/Application Support/Firefox/Profiles/*/Cache"
    
    # Docker
    "*/Library/Containers/com.docker.docker"
    
    # Virtual Machines
    "*/Virtual Machines"
    "*/Parallels"
    "*/VirtualBox VMs"
    
    # Large app data that can be reinstalled
    "*/Library/Application Support/Spotify/PersistentCache"
    "*/Library/Application Support/Adobe/Common"
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