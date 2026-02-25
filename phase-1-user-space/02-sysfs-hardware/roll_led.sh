#!/bin/bash

# Array of the onboard LED paths
# Pre-open file descriptors for brightness (3, 4, 5, 6)
exec 3> /sys/class/leds/beaglebone:green:usr0/brightness
exec 4> /sys/class/leds/beaglebone:green:usr1/brightness
exec 5> /sys/class/leds/beaglebone:green:usr2/brightness
exec 6> /sys/class/leds/beaglebone:green:usr3/brightness

echo "Starting Rolling LED pattern... (Press Ctrl+C to stop)"
trap 'echo "Restoring defaults..."; exit' SIGINT

while true; do
    for fd in {3..6}; do
        echo 1 >&$fd
        # Use 'usleep' for microsecond precision if available, 
        # or a very small sleep.
        sleep 0.05 
        echo 0 >&$fd
    done
done