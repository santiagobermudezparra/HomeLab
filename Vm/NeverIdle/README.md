# NeverIdle Setup Guide

NeverIdle is a utility that helps prevent cloud servers from being hibernated due to inactivity by generating controlled resource usage at regular intervals.

## What is NeverIdle?
NeverIdle artificially consumes system resources at configurable intervals:
- CPU usage at specified intervals or percentage
- Memory allocation at a fixed amount
- Network testing with configurable frequency
- All with minimal impact on actual workloads (runs at lowest process priority)

## Oracle Cloud Optimization
For Oracle Cloud Infrastructure (OCI) Always Free instances, Oracle may reclaim idle instances if:
- CPU utilization for the 95th percentile is less than 20%
- Network utilization is less than 20%
- Memory utilization is less than 20% (applies to A1 shapes only)

**Recommended parameters for Oracle Cloud:**
- CPU activity: every 10 minutes (`-c 10m0s`)
- Memory allocation: 1GB (`-m 1`)
- Network tests: every 30 minutes (`-n 30m0s`)

## Manual Installation
### 1. Prerequisites
Make sure you have the following tools installed:
```bash
sudo apt update
sudo apt install wget screen -y
```

### 2. Create Directory and Download Binary
```bash
mkdir -p ~/neveridle
cd ~/neveridle
```

Download the appropriate binary for your system architecture:

For ARM64 (e.g., Raspberry Pi, many cloud VMs):
```bash
wget https://github.com/layou233/NeverIdle/releases/download/0.2.3/NeverIdle-linux-arm64
chmod +x NeverIdle-linux-arm64
```

For AMD64/x86_64 (most desktop/server CPUs):
```bash
wget https://github.com/layou233/NeverIdle/releases/download/0.2.3/NeverIdle-linux-amd64
chmod +x NeverIdle-linux-amd64
```

### 3. Create Startup Script
Create a startup script to manage NeverIdle:
```bash
nano ~/start-neveridle.sh
```

Add the following content (with Oracle Cloud optimized parameters):
```bash
#!/bin/bash
# Kill any existing NeverIdle screen session
screen -X -S neveridle quit > /dev/null 2>&1
# Start a new screen session with NeverIdle
cd ~/neveridle
screen -dmS neveridle ./NeverIdle-linux-arm64 -m 1 -c 10m0s -n 30m0s
echo "NeverIdle started in screen session. Check with: screen -r neveridle"
```

Make the script executable:
```bash
chmod +x ~/start-neveridle.sh
```

### 4. Set Up Automatic Start on Reboot
Add the script to your crontab to ensure it starts on reboot:
```bash
(crontab -l 2>/dev/null; echo "@reboot ~/start-neveridle.sh") | crontab -
```

### 5. Start NeverIdle
Execute the startup script:
```bash
~/start-neveridle.sh
```

### 6. Verify It's Running
Check the screen session:
```bash
screen -r neveridle
```

To detach from the screen session without stopping NeverIdle, press `Ctrl+A` followed by `D`.

## Command Parameters
NeverIdle supports the following parameters:
- `-c <duration>`: Enable CPU periodic waste with a specific interval (e.g., `-c 12h23m34s`)
- `-cp <percentage>`: Enable CPU percentage waste (value range 0-1, e.g., `-cp 0.2` for 20%)
- `-m <gigabytes>`: Enable memory allocation of specified GiB (e.g., `-m 2` for 2GB)
- `-n <duration>`: Enable network testing at specified intervals (e.g., `-n 4h`)
- `-t <connections>`: Set number of concurrent connections for network tests (default: 10)
- `-p <priority>`: Set process priority (Linux range: -20 to 19, higher = lower priority)

Example usage:
```bash
./NeverIdle-linux-arm64 -cp 0.15 -m 2 -n 4h
```

## Troubleshooting
- If NeverIdle isn't working, check the screen session is running: `screen -ls`
- To see resource usage impact: `top` or `htop`
- Check crontab entry: `crontab -l`
- Verify your architecture matches the binary: `uname -m`

---

## NeverIdle Setup Script (setup-neveridle.sh)

```bash
#!/bin/bash

# NeverIdle Setup Script
# This script automates the installation and configuration of NeverIdle

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}====================================${RESET}"
echo -e "${BOLD}${BLUE}   NeverIdle Automated Setup        ${RESET}"
echo -e "${BOLD}${BLUE}====================================${RESET}"

# Check if running as root and warn if so
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}Warning: You're running this script as root. It's recommended to run as a normal user.${RESET}"
    read -p "Continue anyway? (y/n): " choice
    if [[ ! "$choice" =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 1
    fi
fi

# Create base directory
echo -e "\n${BOLD}Creating NeverIdle directory...${RESET}"
mkdir -p ~/neveridle
cd ~/neveridle || { echo -e "${RED}Failed to create or access directory${RESET}"; exit 1; }
echo -e "${GREEN}Directory created.${RESET}"

# Detect architecture
echo -e "\n${BOLD}Detecting system architecture...${RESET}"
ARCH=$(uname -m)
BINARY_URL=""

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    echo -e "Detected ${GREEN}ARM64${RESET} architecture."
    BINARY_URL="https://github.com/layou233/NeverIdle/releases/download/0.2.3/NeverIdle-linux-arm64"
    BINARY_NAME="NeverIdle-linux-arm64"
elif [ "$ARCH" = "x86_64" ]; then
    echo -e "Detected ${GREEN}AMD64${RESET} architecture."
    BINARY_URL="https://github.com/layou233/NeverIdle/releases/download/0.2.3/NeverIdle-linux-amd64"
    BINARY_NAME="NeverIdle-linux-amd64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${RESET}"
    echo -e "${YELLOW}NeverIdle supports ARM64 and AMD64 architectures.${RESET}"
    exit 1
fi

# Install required packages
echo -e "\n${BOLD}Installing required packages...${RESET}"
sudo apt update && sudo apt install -y wget screen || {
    echo -e "${RED}Failed to install required packages.${RESET}"
    exit 1
}
echo -e "${GREEN}Packages installed successfully.${RESET}"

# Download NeverIdle binary
echo -e "\n${BOLD}Downloading NeverIdle binary...${RESET}"
wget -q --show-progress "$BINARY_URL" -O "$BINARY_NAME" || {
    echo -e "${RED}Failed to download NeverIdle binary.${RESET}"
    exit 1
}
chmod +x "$BINARY_NAME"
echo -e "${GREEN}Download complete and executable permissions set.${RESET}"

# Configure parameters
echo -e "\n${BOLD}Configuring NeverIdle parameters...${RESET}"
echo -e "${YELLOW}Oracle Cloud requires regular activity (>20% utilization) to prevent instance reclamation.${RESET}"
echo -e "${YELLOW}Recommended settings for Oracle Cloud: CPU every 10m, 1GB memory, network tests every 30m.${RESET}"

read -p "CPU wasting interval (e.g., 10m, 1h): " CPU_INTERVAL
[ -z "$CPU_INTERVAL" ] && CPU_INTERVAL="10m0s"

read -p "Memory allocation in GB (e.g., 1, 2): " MEMORY_GB
[ -z "$MEMORY_GB" ] && MEMORY_GB="1"

read -p "Network testing interval (e.g., 30m, 1h): " NETWORK_INTERVAL
[ -z "$NETWORK_INTERVAL" ] && NETWORK_INTERVAL="30m0s"

echo -e "${GREEN}Parameters configured.${RESET}"

# Create startup script
echo -e "\n${BOLD}Creating startup script...${RESET}"
cat > ~/start-neveridle.sh << EOF
#!/bin/bash

# Kill any existing NeverIdle screen session
screen -X -S neveridle quit > /dev/null 2>&1

# Start a new screen session with NeverIdle
cd ~/neveridle
screen -dmS neveridle ./$BINARY_NAME -c $CPU_INTERVAL -m $MEMORY_GB -n $NETWORK_INTERVAL

echo "NeverIdle started in screen session. Check with: screen -r neveridle"
EOF

chmod +x ~/start-neveridle.sh
echo -e "${GREEN}Startup script created at ~/start-neveridle.sh${RESET}"

# Setup Crontab for autostart
echo -e "\n${BOLD}Setting up autostart on reboot...${RESET}"
(crontab -l 2>/dev/null | grep -v "start-neveridle.sh"; echo "@reboot ~/start-neveridle.sh") | crontab -
echo -e "${GREEN}Crontab entry added for autostart on reboot.${RESET}"

# Start NeverIdle
echo -e "\n${BOLD}Starting NeverIdle...${RESET}"
~/start-neveridle.sh
echo -e "${GREEN}NeverIdle started in a screen session.${RESET}"

# Show instructions
echo -e "\n${BOLD}${BLUE}====================================${RESET}"
echo -e "${BOLD}${GREEN}NeverIdle Setup Complete!${RESET}"
echo -e "${BOLD}${BLUE}====================================${RESET}"
echo -e "\n${BOLD}Commands to remember:${RESET}"
echo -e "  ${YELLOW}screen -r neveridle${RESET}       - View NeverIdle output"
echo -e "  ${YELLOW}screen -d${RESET}                 - Detach from screen (Ctrl+A, D)"
echo -e "  ${YELLOW}~/start-neveridle.sh${RESET}      - Restart NeverIdle manually"
echo -e "  ${YELLOW}screen -X -S neveridle quit${RESET} - Stop NeverIdle"
echo -e "\n${BOLD}Current configuration:${RESET}"
echo -e "  CPU Interval: ${GREEN}$CPU_INTERVAL${RESET}"
echo -e "  Memory Usage: ${GREEN}$MEMORY_GB GB${RESET}"
echo -e "  Network Test Interval: ${GREEN}$NETWORK_INTERVAL${RESET}"
echo -e "\n${YELLOW}NeverIdle will automatically start on system reboot.${RESET}"
```