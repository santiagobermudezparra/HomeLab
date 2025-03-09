# NeverIdle Setup Guide

NeverIdle is a utility that helps prevent cloud servers from being hibernated due to inactivity by generating controlled resource usage at regular intervals.

## What is NeverIdle?

NeverIdle artificially consumes system resources at configurable intervals:
- CPU usage at specified intervals or percentage
- Memory allocation at a fixed amount
- Network testing with configurable frequency
- All with minimal impact on actual workloads (runs at lowest process priority)

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

Add the following content (adjust parameters as needed):
```bash
#!/bin/bash

# Kill any existing NeverIdle screen session
screen -X -S neveridle quit > /dev/null 2>&1

# Start a new screen session with NeverIdle
cd ~/neveridle
screen -dmS neveridle ./NeverIdle-linux-arm64 -m 1 -c 2h0m0s -n 4h0m0s

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

## Docker Deployment

1. Download Dockerfile:
```bash
wget https://raw.githubusercontent.com/layou233/NeverIdle/master/Dockerfile
```

2. Build the image:
```bash
# ARM machine
docker build -t neveridle:latest .
# AMD machine
docker build --build-arg ARCH=amd64 -t neveridle:latest .
```

3. Run:
```bash
docker run -d --name neveridle neveridle:latest -c 1h -m 2 -n 4h
```

## Troubleshooting

- If NeverIdle isn't working, check the screen session is running: `screen -ls`
- To see resource usage impact: `top` or `htop`
- Check crontab entry: `crontab -l`
- Verify your architecture matches the binary: `uname -m`