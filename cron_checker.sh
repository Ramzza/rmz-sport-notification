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

sendemail -f "$EMAIL" -t "$TO" -u "Test Cron Timer" -m "Email triggered by Crontab" -s "$SMTP_SERVER:$SMTP_PORT" -xu "$EMAIL" -xp "$PASSWORD" -o tls=$SSL

log_with_date "Script finished"
