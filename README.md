# Backupchik - Mac Backup System

A set of scripts for creating incremental backups using rsync hardlinks.

## Scripts Overview

### 1. hourly_backup.sh
Creates hourly incremental snapshots of your MacBook to an external SSD (SSD1).
- Source: Local MacBook system
- Destination: `/Volumes/SSD1/Backups/MacBook/hourly/YYYY-MM-DD_HH-MM`
- Type: Incremental snapshots using rsync with hardlinks
- Retention: 30 days

### 2. daily_clone_ssd1_to_ssd2.sh
Creates daily backups of SSD1 to SSD2 for redundancy.
- Source: `/Volumes/SSD1`
- Destination: `/Volumes/SSD2/Backups/SSD1/daily/YYYY-MM-DD`
- Type: Incremental snapshots using rsync with hardlinks
- Retention: 90 days

### 3. prune_old_snapshots.sh
Maintains backup retention by removing old snapshots:
- Hourly snapshots: removes backups older than 30 days
- Daily snapshots: removes backups older than 90 days

## Setup Instructions

1. Clone this repository to your local machine
2. Make scripts executable:
   ```bash
   chmod +x hourly_backup.sh daily_clone_ssd1_to_ssd2.sh prune_old_snapshots.sh
   ```

## Scheduling Backups

### Using launchd (Recommended for macOS)

1. Create the following launchd plist files in `~/Library/LaunchAgents/`:

```xml
<!-- com.user.hourly.backup.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.hourly.backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/hourly_backup.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
</dict>
</plist>

<!-- com.user.daily.backup.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.daily.backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/daily_clone_ssd1_to_ssd2.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>2</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>

<!-- com.user.prune.snapshots.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.prune.snapshots</string>
    <key>ProgramArguments</key>
    <array>
        <string>/path/to/prune_old_snapshots.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
</dict>
</plist>
```

2. Load the launchd jobs:
```bash
launchctl load ~/Library/LaunchAgents/com.user.hourly.backup.plist
launchctl load ~/Library/LaunchAgents/com.user.daily.backup.plist
launchctl load ~/Library/LaunchAgents/com.user.prune.snapshots.plist
```

### Alternative: Using cron

Add the following to your crontab (`crontab -e`):

```cron
# Run hourly backup every hour
0 * * * * /path/to/hourly_backup.sh

# Run daily backup at 2 AM
0 2 * * * /path/to/daily_clone_ssd1_to_ssd2.sh

# Run pruning at 3 AM
0 3 * * * /path/to/prune_old_snapshots.sh
```

## Important Notes

1. Ensure external drives (SSD1 and SSD2) are mounted before running backups
2. First backup might take longer as it's a full copy
3. Subsequent backups are incremental and much faster
4. Scripts use hardlinks to save space while maintaining full snapshots
5. Check logs regularly to ensure backups are running correctly 