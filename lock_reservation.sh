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

# Check if all required arguments are provided
if [ $# -ne 6 ]; then
  log_with_date "Usage: $0 <date YYYY-MM-DD> <time HH:MM> <cookie> <location_id> <service_id> <staff_id>"
  exit 1
fi

# Assign arguments to variables
given_date="$1 $2" # Combines date and time
cookie="client_session=$3"
location_id=$4
service_id=$5
staff_id=$6
start_time=$2

log_with_date "Given date: $given_date"

# Convert the given date to timestamp in GMT+3
dateUnix=$(date -d "$given_date GMT+3" +%s)

# Subtract 3 hours (10800 seconds) to get the UTC timestamp
dateUtcUnix=$((dateUnix - 10800))

# Define the JSON body using the variables
jsonBody=$(
  cat <<EOF
{
  "appointments": [
    {
      "dateUnix": $dateUnix,
      "dateUtcUnix": $dateUtcUnix,
      "location_id": $location_id,
      "service_id": $service_id,
      "staff_id": "$staff_id",
      "startTime": "$start_time",
      "originalSlot": 0
    }
  ],
  "group_id": null
}
EOF
)

# Log request details
log_with_date "request body: $jsonBody"

# Send the request
response=$(curl -sX POST "$CONST_RESERVATION_URL" \
  -H "Content-Type: application/json" \
  -H "Cookie: $cookie" \
  -d "$jsonBody")

# Log response
log_with_date "response: $response"

# Check if response contains "success": 0
success=$(echo $response | jq -r '.success')
if [ "$success" -eq 0 ]; then
  log_with_date "Operation failed, success: $success"
  exit 1
fi

# Extract appointment_group_id
appointment_group_id=$(echo $response | jq -r '.appointment_group_id')

# Check if appointment_group_id is valid and return it, otherwise return 0
if [[ $appointment_group_id =~ ^[0-9]+$ ]]; then
  log_with_date "appointment_group_id: $appointment_group_id"
  echo $appointment_group_id
  exit 0
else
  log_with_date "Invalid appointment_group_id"
  exit 1
fi

log_with_date "Script finished"
