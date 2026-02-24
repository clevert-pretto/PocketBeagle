#!/bin/bash

LOG_FILE="/home/debian/cpu_temp_log.txt"
TEMP_FILE="/sys/class/thermal/thermal_zone0/temp"

if [ -f "$TEMP_FILE" ]; then
    RAW_TEMP=$(cat "$TEMP_FILE")
    TEMP_C=$((RAW_TEMP / 1000)) # Integer division for Celsius
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    
    echo "[$TIMESTAMP] Boot Temperature: ${TEMP_C}°C" >> "$LOG_FILE"
else
    echo "Error: Thermal sensor not found." >> "$LOG_FILE"
fi