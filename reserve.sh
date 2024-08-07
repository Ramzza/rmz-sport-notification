#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date '+%a %Y-%m-%d %H:%M:%S.%3N') - $(basename "$0"): $1" | tee -a $log_file
}

log_with_date "Script started"

# Check if the.env file exists
if [ -f "$ENV_FILE" ]; then

    # Read the.env file line by line
    while IFS= read -r line; do

        # Skip comments and empty lines
        if [[ "$line" =~ ^\s*#.*$ || -z "$line" ]]; then
            continue
        fi

        # Split the line into key and value
        key=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)

        # Remove single quotes, double quotes, and leading/trailing spaces from the value
        value=$(echo "$value" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//' -e 's/^[ \t]*//;s/[ \t]*$//')

        # Assign the key and value as local variables
        eval "$key='$value'"
    done <"$ENV_FILE"
fi

# Check if the number of arguments is within the expected range
if [ $# -gt 6 ] || [ $# -eq 5 ]; then
    log_with_date "Usage: $0 <cookie> <location_id> <service_id> <staff_id> [<date YYYY-MM-DD> [<time HH:MM>]]"
    exit 1
fi

if [ $# -lt 4 ]; then
    cookie=$CONST_COOKIE
    location_id=$2
    service_id=$3
    staff_id=$4
else
    # Assign the first four mandatory arguments to variables
    cookie=$1
    location_id=$2
    service_id=$3
    staff_id=$4
fi

# Initialize date and time with defaults if not provided
if [ $# -eq 6 ]; then
    # If both date and time are provided
    given_date=$5
    selected_hour=$6
else
    # If neither date nor time are provided, calculate defaults
    given_date=$(date -d "2 weeks" +%Y-%m-%d)
    current_minute=$(date +%M)
    if [ "$current_minute" -lt 45 ]; then
        selected_hour=$(date +%H:00)
    else
        selected_hour=$(date -d "next hour" +%H:00)
    fi
fi

log_with_date "Given date: $given_date"
log_with_date "Selected hour: $selected_hour"

# Call lock_reservation.sh with the calculated date, time, and the additional parameters
lock_result=$("$SCRIPT_DIR/lock_reservation.sh" "$given_date" "$selected_hour" "$cookie" "$location_id" "$service_id" "$staff_id")
lock_result=$(echo "$lock_result" | tail -n 1)
log_with_date "Reservation locked: $lock_result"

# Check if lock_reservation.sh executed successfully
if ! [[ "$lock_result" =~ ^-?[0-9]+$ ]]; then
    log_with_date "Error: lock_result is not an integer."
    exit 1
elif [ "$lock_result" -ne 0 ]; then
    # If successful, pass the result and additional parameters to finalize_reservation
    finalize_result=$("$SCRIPT_DIR/finalize_reservation.sh" "$cookie" "$lock_result")
    log_with_date "Reservation finalized: $finalize_result"
else
    log_with_date "Failed to lock reservation."
fi

log_with_date "Script finished"
