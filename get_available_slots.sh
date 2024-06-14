#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your .env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Default values for optional parameters
staff_id=""
convenient_hours=""

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
    --staff_id)
        staff_id="$2"
        shift
        ;;
    --date)
        given_date="$2"
        shift
        ;;
    --convenient_hours)
        convenient_hours="$2"
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
if [ -z "$cookie" ] || [ -z "$location_id" ] || [ -z "$service_id" ]; then
    echo "Usage: $0 --cookie <cookie> --location_id <location_id> --service_id <service_id> [--staff_id <staff_id>] [--date <YYYY-MM-DD>] [--convenient_hours <hours>]"
    exit 1
fi

# Load environment variables from .env file
if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^\s*#.*$ || -z "$line" ]]; then
            continue
        fi
        key=$(echo "$line" | cut -d '=' -f 1)
        value=$(echo "$line" | cut -d '=' -f 2-)
        value=$(echo "$value" | sed -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//' -e 's/^[ \t]*//;s/[ \t]*$//')
        eval "$key='$value'"
    done <"$ENV_FILE"
fi

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date) - R: $1" | tee -a $log_file
}

# If a date is not provided, calculate the date for two weeks from now
if [ -z "$given_date" ]; then
    given_date=$(date -d "2 weeks" +%Y-%m-%d)
fi

# If convenient hours are not provided, use the environment variable
if [ -z "$convenient_hours" ]; then
    convenient_hours=$CONST_CONVENIENT_HOURS # Use environment variable or default
fi

# Convert the given date to a timestamp
curr_date=$(date -d "$given_date" +%s)

# Construct the URL
url="${CONST_URL_BASE}?service_id=${service_id}&location_id=${location_id}&date=${curr_date}&day_only=1"
if [ -n "$staff_id" ]; then
    url="${url}&staff_id=${staff_id}"
fi

log_with_date "Checking for: $(date -d @$curr_date '+%F (%A)')"

# Execute the curl command and process the output
result=$(curl -skb client_session=$cookie $url |
    jq -r '.available_slots[] | select(.is_available == 1) | "\(.time | tonumber | . + 10800 | todate) \(.staff_id)"' |
    grep -E "(${convenient_hours}):")

# Concatenate the result to a variable
if [ -n "$result" ]; then
    log_with_date "Found! $result"
else
    log_with_date "No available slots found"
fi
