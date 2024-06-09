#!/bin/bash

# Specify the path to your.env file relative to the script directory
ENV_FILE=".env"

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

log_file="reserve.log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date) - R: $1" | tee -a $log_file
}

# Check if at least the minimum required arguments are provided
if [ $# -lt 2 ] || [ $# -gt 4 ]; then
    log_with_date "Usage: $0 <cookie> <place> [<date YYYY-MM-DD>] [<convenient_hours>]"
    exit 1
fi

# Assign arguments to variables
cookie=$1
place=$2

# If a date is provided, use it; otherwise, calculate the date for two weeks from now
if [ $# -ge 3 ]; then
    given_date=$3
else
    given_date=$(date -d "2 weeks" +%Y-%m-%d)
fi

# If convenient hours are provided, use them; otherwise, use the environment variable
if [ $# -eq 4 ]; then
    convenient_hours=$4
else
    convenient_hours=$CONST_CONVENIENT_HOURS # Use environment variable or default
fi

# Convert the given date to a timestamp
curr_date=$(date -d "$given_date" +%s)

# Determine the URL based on the place
case $place in
PLACE_1)
    url="${CONST_URL_PLACE_1}${curr_date}"
    ;;
PLACE_2)
    url="${CONST_URL_PLACE_2}${curr_date}"
    ;;
*)
    log_with_date "Invalid place specified."
    exit 1
    ;;
esac

log_with_date "Checking $place for: $(date -d @$curr_date '+%F (%A)')"

# Execute the curl command and process the output
result=$(curl -skb client_session=$cookie $url |
    jq -r '.available_slots[] | select(.is_available == 1) | "\(.time | tonumber | . + 10800 | todate) \(.staff_id)"' |
    grep -E "(${convenient_hours}):")

# Concatenate the result to a variable
if [ -n "$result" ]; then
    log_with_date "Found!"
    log_with_date "$place:"
    log_with_date "$result"
else
    log_with_date "No available slots found."
fi
