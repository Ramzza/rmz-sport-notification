#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date '+%a %Y-%m-%d %H:%M:%S.%3N') - $(basename "$0"): $1" | tee -a $log_file
}

# Get the current minute
start_minute=$(date +%M)

while true; do
    # Get the current time
    current_time=$(date '+%M:%S.%3N')
    current_minute=$(date +%M)
    current_second=$(date +%S)

    log_with_date "Current time: $current_time"

    # Check if the current minute is different from the start minute
    if [ "$current_minute" != "$start_minute" ] && [ "$current_second" -eq 1 ]; then
        log_with_date "Reached :01 of the next minute. Exiting."
        exit 0
    fi

    # Determine sleep amount based on the current second
    if [ "$current_minute" != "$start_minute" ]; then
        sleep_amount=0.1
    elif [ "$current_minute" == "$start_minute" ] && [ "$current_second" -lt 54 ]; then
        sleep_amount=5
    elif [ "$current_minute" == "$start_minute" ] && [ "$current_second" -lt 59 ]; then
        sleep_amount=1
    else
        sleep_amount=0.1
    fi

    log_with_date "Sleeping for $sleep_amount seconds"
    sleep $sleep_amount
done
