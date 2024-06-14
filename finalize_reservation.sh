#!/bin/bash

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"
log_file="$SCRIPT_DIR/$(basename "$0" .sh).log"

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

# Function to log messages with date and time
log_with_date() {
  echo "$(date) - FR: $1" | tee -a $log_file
}

# Check if the correct number of arguments was provided
if [ $# -ne 2 ]; then
  log_with_date "Usage: $0 <cookie_value> <group_id>"
  exit 1
fi

# The first argument is the cookie value, and the second is the group ID
cookie_value="client_session=$1"
group_id="$2"
log_with_date "Cookie Value: $cookie_value"
log_with_date "Group ID: $group_id"

# Validate the group ID
if [[ ! -z "$group_id" ]] && [[ "$group_id" =~ ^[0-9]+$ ]]; then
  log_with_date "Appointment Group ID: $group_id"
  log_with_date "Appointment Group ID is valid"
else
  log_with_date "Appointment Group ID is invalid"
  exit 1
fi

# Calculate the current timestamp
dateUnix=$(date +%s)

# Define the JSON body with the current timestamp and group_id
jsonBody=$(
  cat <<EOF
{
  "clients": [
    {
      "own_appointment": 1,
      "dateUnix": $dateUnix,
      "appointment_id": $group_id
    }
  ]
}
EOF
)

# Send the PUT request
response=$(curl -sX PUT "$CONST_RESERVATION_URL/$group_id" \
  -H "Content-Type: application/json" \
  -H "Cookie: $cookie_value" \
  -d "$jsonBody")

# Optionally, log the response with date and time
log_with_date "$response"
