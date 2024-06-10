#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your .env file relative to the script directory
log_file="$SCRIPT_DIR/targeted_reservation.log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date) - R: $1" | tee -a $log_file
}

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --cookie)
        cookie="$2"
        shift
        ;;
    --location_id)
        location_id="$2"
        shift
        ;;
    --service_id)
        service_id="$2"
        shift
        ;;
    --date)
        date="$2"
        shift
        ;;
    --time)
        time="$2"
        shift
        ;;
    *)
        echo "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    shift
done

# Check if the required arguments are provided
if [ -z "$cookie" ] || [ -z "$location_id" ] || [ -z "$service_id" ] || [ -z "$date" ]; then
    log_with_date "Usage: $0 --cookie <cookie> --location_id <location_id> --service_id <service_id> --date <YYYY-MM-DD> [--time <HH:MM>]"
    exit 1
fi

# Invoke get_available_slots.sh with the necessary parameters
# Note: Adjust the path to get_available_slots.sh as necessary
output=$(./get_available_slots.sh --cookie "$cookie" --location_id "$location_id" --service_id "$service_id" --date "$date" --convenient_hours "$time")
staff_id=$(echo "$output" | grep -oE '[0-9]+$' | tail -n1)

# Parse the output to find a matching slot
# This is a simplified example; you may need to adjust the parsing logic based on the actual output format
if [[ "$staff_id" =~ ^[0-9]+$ ]] && ((staff_id > 0)); then
    log_with_date "Found matching slot with staff_id: $staff_id"

    # Call reserve.sh with the necessary parameters
    # Note: Adjust the path to reserve.sh as necessary
    ./reserve.sh "$cookie" "$location_id" "$service_id" "$staff_id" "$date" "$time"
else
    log_with_date "No matching slots found for the specified date and time."
fi
