#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
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

# Check if exactly one argument (the cookie value) is provided
if [ "$#" -ne 1 ]; then
    if [ -z "$CONST_COOKIE" ]; then
        log_with_date "Usage: $0 <cookie_value>"
        log_with_date "Or set CONST_COOKIE environment variable. Script finished"
        exit 1
    else
        cookie_value="$CONST_COOKIE"
    fi
else
    # Assign the first argument to a variable
    cookie_value="$1"
fi

log_with_date "Checking token validity..."
status_code=$(curl -skI -H "cookie: client_session=$cookie_value" "$CONST_URL_OWN_RESERVATION" | head -n 1 | awk '{print $2}')

if [ "$status_code" -ne 401 ]; then
    log_with_date "Token is still valid. Script finished"
    exit 0
fi

log_with_date "Token is invalid. Getting new token..."
new_cookie=$(curl -sk -L -c - -X POST -H "Content-Type: application/json" -d "$CONST_LOGIN_PAYLOAD" "$CONST_URL_LOGIN" | grep 'client_session' | awk '{print $7}')

log_with_date "Writing new cookie to .env file..."
sed -i "s/CONST_COOKIE=\".*\"/CONST_COOKIE=\"$new_cookie\"/g" $ENV_FILE

log_with_date "Script finished"
