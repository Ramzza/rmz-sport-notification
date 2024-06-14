#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date) - R: $1" | tee -a $log_file
}

log_with_date "$(basename "$0") script started"

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

# Check if exactly one argument (the cookie value) is provided
if [ "$#" -ne 1 ]; then
    if [ -z "$CONST_COOKIE" ]; then
        log_with_date "Usage: $0 <cookie_value>"
        log_with_date "Or set CONST_COOKIE environment variable."
        exit 1
    else
        cookie_value="$CONST_COOKIE"
    fi
else
    # Assign the first argument to a variable
    cookie_value="$1"
fi

# Execute the GET request with the provided cookie and return the result
curl -s -H "cookie: client_session=$cookie_value" "$CONST_URL_OWN_RESERVATION" | jq -r '.appointments[] | "\(.appointment_date) \(.appointment_time) \(.business_name)"'

log_with_date "$(basename "$0") script finished"
