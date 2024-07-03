#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your .env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

# Function to prepend current date and time to log messages
log_with_date() {
    echo "$(date '+%a %Y-%m-%d %H:%M:%S.%3N') - $(basename "$0"): $1" | tee -a $log_file
}

log_with_date "Script started"

# Default to USER_1 if no user parameter is given
user="USER_1"

# Check if exactly one argument (the user) is provided
if [ "$#" -eq 1 ]; then
    case $1 in
    USER_1 | USER_2 | USER_3)
        user="$1"
        ;;
    *)
        log_with_date "Invalid user. Please specify USER_1, USER_2, or USER_3. Script finished"
        exit 1
        ;;
    esac
fi

# Check if the .env file exists
if [ -f "$ENV_FILE" ]; then

    # Read the .env file line by line
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

# Use the selected user to determine the corresponding cookie and login payload variables
cookie_var_name="CONST_COOKIE_${user#USER_}"
login_payload_var_name="CONST_LOGIN_PAYLOAD_${user#USER_}"

cookie_value="${!cookie_var_name}"
login_payload="${!login_payload_var_name}"

if [ -z "$cookie_value" ]; then
    log_with_date "Cookie for $user not found. Script finished"
    exit 1
fi

log_with_date "Checking token validity for $user..."
status_code=$(curl -skI -H "cookie: client_session=$cookie_value" "${CONST_URL_OWN_RESERVATION}" | head -n 1 | awk '{print $2}')

if [ "$status_code" -ne 401 ]; then
    log_with_date "Token for $user is still valid. Script finished"
    exit 0
fi

log_with_date "Token for $user is invalid. Getting new token..."
new_cookie=$(curl -sk -L -c - -X POST -H "Content-Type: application/json" -d "$login_payload" "${CONST_URL_LOGIN}" | grep 'client_session' | awk '{print $7}')

log_with_date "Writing new cookie to .env file for $user..."
sed -i "s/${cookie_var_name}=\".*\"/${cookie_var_name}=\"$new_cookie\"/g" $ENV_FILE

log_with_date "Script finished"
