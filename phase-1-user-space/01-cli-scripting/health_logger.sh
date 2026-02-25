#!/bin/bash

# Define paths
LOG_FILE="/home/debian/system_health.log"

# 1. Extract Uptime (the first number in the file is seconds)
UPTIME_RAW=$(cat /proc/uptime | awk '{print $1}')
# Convert to integer for simplicity
UPTIME_SEC=${UPTIME_RAW%.*}

# 2. Extract Free Memory (searching for MemFree in /proc/meminfo)
MEM_FREE=$(grep "MemFree" /proc/meminfo | awk '{print $2 " " $3}')

# 3. Get Timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# 4. Write to log
echo "[$TIMESTAMP] Uptime: ${UPTIME_SEC}s | Free RAM: $MEM_FREE" >> "$LOG_FILE"