#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your .env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date) - $(basename "$0"): $1" | tee -a $log_file
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

# Initialize user with default value
user="USER_1"

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
    --cookie)
        cookie="$2"
        shift
        ;;
    --location)
        location="$2"
        shift
        if [[ "$location" == "GHE" ]]; then
            location_id="$CONST_LOCATION_1"
            service_id="$CONST_SPORT_1"
        elif [[ "$location" == "MON" ]]; then
            location_id="$CONST_LOCATION_2"
            service_id="$CONST_SPORT_2"
        else
            log_with_date "Invalid location. Please specify MON or GHE."
            exit 1
        fi
        ;;
    --date)
        date="$2"
        shift
        ;;
    --time)
        time="$2"
        shift
        ;;
    --place)
        place="$2"
        shift
        ;;
    --user)
        user="$2"
        if ! [[ "$user" =~ ^(USER_1|USER_2|USER_3)$ ]]; then
            log_with_date "Invalid user. Please specify USER_1, USER_2, or USER_3."
            exit 1
        fi
        shift
        ;;
    *)
        log_with_date "Unknown parameter passed: $1"
        exit 1
        ;;
    esac
    shift
done

# Dynamically determine the cookie variable name based on the user
cookie_var_name="CONST_COOKIE_${user#USER_}"

# Use the dynamically determined cookie variable name to get its value
cookie="${!cookie_var_name}"

# After the parameter parsing loop
if [ -z "$cookie" ]; then
    if [ -z "$CONST_COOKIE" ]; then
        log_with_date "Cookie is required. Please provide a cookie or set CONST_COOKIE."
        exit 1
    else
        cookie="$CONST_COOKIE"
    fi
fi

# Check if the required arguments are provided
if [ -z "$cookie" ] || [ -z "$location" ]; then
    log_with_date "Usage: $0 --cookie <cookie> --location <MON|GHE> --date <YYYY-MM-DD> [--time <HH:MM>]"
    exit 1
fi

# Set default date to two weeks from now if not provided
if [ -z "$date" ]; then
    date=$(date -d "+2 weeks" +%Y-%m-%d)
fi

# Use place as staff_id if provided, otherwise invoke get_available_slots.sh
if [ -n "$place" ]; then
    staff_id="$place"
    log_with_date "Using provided place as staff_id: $staff_id"
else
    # Invoke get_available_slots.sh with the necessary parameters
    output=$("$SCRIPT_DIR/get_available_slots.sh" --cookie "$cookie" --location_id "$location_id" --service_id "$service_id" --date "$date" --convenient_hours "$time")
    staff_id=$(echo "$output" | grep -oE '[0-9]+$' | tail -n1)
    log_with_date "Found matching slot with staff_id: $staff_id"
fi

# Parse the output to find a matching slot
# This is a simplified example; you may need to adjust the parsing logic based on the actual output format
if [[ "$staff_id" =~ ^[0-9]+$ ]] && ((staff_id > 0)); then
    # Call reserve.sh with the necessary parameters
    # Note: Adjust the path to reserve.sh as necessary
    "$SCRIPT_DIR/reserve.sh" "$cookie" "$location_id" "$service_id" "$staff_id" "$date" "$time"
else
    log_with_date "No matching slots found for location $location at $date $time."
fi

log_with_date "Script finished"
