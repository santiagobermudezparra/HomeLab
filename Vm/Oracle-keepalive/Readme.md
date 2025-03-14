# Oracle Cloud Keepalive

A lightweight service to prevent Oracle Cloud Infrastructure Always Free instances from being reclaimed due to inactivity.

## Background

Oracle Cloud Infrastructure (OCI) may reclaim idle Always Free compute instances. According to Oracle's documentation, instances are considered idle if, during a 7-day period:

- CPU utilization for the 95th percentile is less than 20%
- Network utilization is less than 20%
- Memory utilization is less than 20% (applies to A1 shapes only)

This service creates controlled, low-priority resource usage at regular intervals to keep your instance active while having minimal impact on actual workloads.

## Features

- **CPU Activity**: Generates CPU load for 46 seconds every 5 minutes
- **Memory Usage**: Allocates and releases 500MB of memory every 30 minutes
- **Network Activity**: Makes small web requests every 15 minutes
- **Low Priority**: Uses `nice` priority 19 (lowest) to avoid impacting real workloads
- **Automatic**: Runs as a systemd service that starts automatically on boot
- **Logging**: Maintains logs at `/var/log/oracle-keepalive.log`

## Installation

### Automatic Installation

1. Download the installation script:
```bash
curl -O https://raw.githubusercontent.com/yourusername/oracle-keepalive/main/install-keepalive.sh
```

2. Make it executable and run it:
```bash
chmod +x install-keepalive.sh
sudo ./install-keepalive.sh
```

### Manual Installation

1. Create the script:
```bash
sudo nano /usr/local/bin/oracle-keepalive.sh
```

2. Paste the script content (see below), then save and exit (Ctrl+O, Enter, Ctrl+X).

3. Make it executable:
```bash
sudo chmod +x /usr/local/bin/oracle-keepalive.sh
```

4. Create the service file:
```bash
sudo nano /etc/systemd/system/oracle-keepalive.service
```

5. Paste the service file content (see below), then save and exit.

6. Enable and start the service:
```bash
sudo systemctl daemon-reload
sudo systemctl enable oracle-keepalive.service
sudo systemctl start oracle-keepalive.service
```

## Script Content

**oracle-keepalive.sh:**
```bash
#!/bin/bash
# Script to prevent Oracle Cloud instances from being reclaimed due to inactivity

# Log file
LOG_FILE="/var/log/oracle-keepalive.log"

# Create log file if it doesn't exist
touch $LOG_FILE

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "Starting Oracle keepalive service..."

# Create CPU load function (runs md5sum on /dev/zero for 46 seconds)
create_cpu_load() {
    log "Generating CPU load..."
    timeout 46 nice -n 19 md5sum /dev/zero > /dev/null 2>&1
    log "CPU load completed"
}

# Create memory activity (allocates and releases 500MB of memory)
create_memory_activity() {
    log "Generating memory activity..."
    # Create a 500MB file in memory and then remove it
    dd if=/dev/zero of=/dev/shm/memfile bs=1M count=500 > /dev/null 2>&1
    sleep 5
    rm /dev/shm/memfile
    log "Memory activity completed"
}

# Create network activity (makes a small web request)
create_network_activity() {
    log "Generating network activity..."
    # Try curl first, fall back to wget if curl is not available
    if command -v curl > /dev/null; then
        curl -s https://example.com > /dev/null 2>&1
    elif command -v wget > /dev/null; then
        wget -q -O /dev/null https://example.com > /dev/null 2>&1
    else
        log "ERROR: Neither curl nor wget is installed"
    fi
    log "Network activity completed"
}

# Main loop
while true; do
    # Create CPU load
    create_cpu_load
    
    # Create memory activity every 30 minutes
    if [ $(( $(date +%M) % 30 )) -eq 0 ]; then
        create_memory_activity
    fi
    
    # Create network activity every 15 minutes
    if [ $(( $(date +%M) % 15 )) -eq 0 ]; then
        create_network_activity
    fi
    
    # Wait until the next 5-minute mark
    sleep $(( 300 - $(date +%s) % 300 ))
done
```

**oracle-keepalive.service:**
```
[Unit]
Description=Oracle Cloud Keepalive Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/oracle-keepalive.sh
Restart=always
RestartSec=10
User=root
Nice=19
IOSchedulingClass=idle
CPUSchedulingPolicy=idle

[Install]
WantedBy=multi-user.target
```

## Installation Script

```bash
#!/bin/bash
# Installation script for Oracle Cloud Keepalive Service

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Installing Oracle Cloud Keepalive Service..."

# Create script directory if it doesn't exist
mkdir -p /usr/local/bin

# Create the script
cat > /usr/local/bin/oracle-keepalive.sh << 'EOF'
#!/bin/bash
# oracle-keepalive.sh
# Script to prevent Oracle Cloud instances from being reclaimed due to inactivity
# This script creates controlled CPU, memory, and network activity

# Log file
LOG_FILE="/var/log/oracle-keepalive.log"

# Create log file if it doesn't exist
touch $LOG_FILE

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log "Starting Oracle keepalive service..."

# Create CPU load function (runs md5sum on /dev/zero for 46 seconds)
create_cpu_load() {
    log "Generating CPU load..."
    timeout 46 nice -n 19 md5sum /dev/zero > /dev/null 2>&1
    log "CPU load completed"
}

# Create memory activity (allocates and releases 500MB of memory)
create_memory_activity() {
    log "Generating memory activity..."
    # Create a 500MB file in memory and then remove it
    dd if=/dev/zero of=/dev/shm/memfile bs=1M count=500 > /dev/null 2>&1
    sleep 5
    rm /dev/shm/memfile
    log "Memory activity completed"
}

# Create network activity (makes a small web request)
create_network_activity() {
    log "Generating network activity..."
    # Try curl first, fall back to wget if curl is not available
    if command -v curl > /dev/null; then
        curl -s https://example.com > /dev/null 2>&1
    elif command -v wget > /dev/null; then
        wget -q -O /dev/null https://example.com > /dev/null 2>&1
    else
        log "ERROR: Neither curl nor wget is installed"
    fi
    log "Network activity completed"
}

# Main loop
while true; do
    # Create CPU load
    create_cpu_load
    
    # Create memory activity every 30 minutes
    if [ $(( $(date +%M) % 30 )) -eq 0 ]; then
        create_memory_activity
    fi
    
    # Create network activity every 15 minutes
    if [ $(( $(date +%M) % 15 )) -eq 0 ]; then
        create_network_activity
    fi
    
    # Wait until the next 5-minute mark
    sleep $(( 300 - $(date +%s) % 300 ))
done
EOF

# Make script executable
chmod +x /usr/local/bin/oracle-keepalive.sh

# Create systemd service file
cat > /etc/systemd/system/oracle-keepalive.service << 'EOF'
[Unit]
Description=Oracle Cloud Keepalive Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/oracle-keepalive.sh
Restart=always
RestartSec=10
User=root
Nice=19
IOSchedulingClass=idle
CPUSchedulingPolicy=idle

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start the service
systemctl daemon-reload
systemctl enable oracle-keepalive.service
systemctl start oracle-keepalive.service

echo "Oracle Cloud Keepalive Service has been installed and started."
echo "You can check the status with: systemctl status oracle-keepalive"
echo "View logs with: tail -f /var/log/oracle-keepalive.log"
```

## Managing the Service

- **Check status**: `sudo systemctl status oracle-keepalive`
- **View logs**: `sudo tail -f /var/log/oracle-keepalive.log`
- **Stop service**: `sudo systemctl stop oracle-keepalive`
- **Start service**: `sudo systemctl start oracle-keepalive`
- **Disable autostart**: `sudo systemctl disable oracle-keepalive`
- **Enable autostart**: `sudo systemctl enable oracle-keepalive`
- **Restart service**: `sudo systemctl restart oracle-keepalive`

## Activity Schedule

| Resource | Frequency | Duration | Priority |
|----------|-----------|----------|----------|
| CPU | Every 5 minutes | 46 seconds | nice 19 (lowest) |
| Memory | Every 30 minutes | ~5 seconds | nice 19 (lowest) |
| Network | Every 15 minutes | ~1-2 seconds | nice 19 (lowest) |

## Compatibility

This script is designed to work alongside other keep-alive solutions like NeverIdle without interference.

## License

MIT License

## Disclaimer

This solution is provided as-is without warranty. Use at your own risk.