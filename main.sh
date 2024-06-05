#!/bin/bash

# Initialize the start date to today
start_date=$(date +%s)
dates=()

# Determine the directory where the script is located
SCRIPT_DIR="$(CDPATH= cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Specify the path to your.env file relative to the script directory
ENV_FILE="$SCRIPT_DIR/.env"

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

# Loop for the next 14 days
for i in $(seq 0 14); do
    # Calculate the Unix timestamp for the next day
    next_day_timestamp=$((start_date + i * 86400))
    dates+=($next_day_timestamp)
done

# Loop through each URL
for curr_date in "${dates[@]}"; do
    this_week=false
    next_week=false
    two_weeks_later=false

    # Get the current day of the week (1 = Monday, 7 = Sunday)
    current_day=$(date +%u)

    # Determine the start of the current week, the start of the next week, and the start of the week after that
    if ((current_day < 2)); then
        # Today is before Thursday, so the current week starts on Monday
        current_week_start=$(date -d "this Monday" +%s)
        next_week_start=$((current_week_start + 604800))         # Start of the next week
        week_after_next_week_start=$((next_week_start + 604800)) # Start of the week after the next week
    else
        # Today is Thursday or later, so the current week starts on the previous Monday
        current_week_start=$(date -d "last Monday" +%s)
        next_week_start=$((current_week_start + 604800))         # Start of the next week
        week_after_next_week_start=$((next_week_start + 604800)) # Start of the week after the next week
    fi

    # Check which week the given timestamp belongs to and echo the corresponding message
    if [[ $curr_date -ge $current_week_start && $curr_date -lt $next_week_start ]]; then
        this_week=true
    elif [[ $curr_date -ge $next_week_start && $curr_date -lt $week_after_next_week_start ]]; then
        next_week=true
    else
        two_weeks_later=true
    fi

    url1="${const_url1}${curr_date}${param}"
    url2="${const_url2}${curr_date}${param}"

    # if curr_date is in this week or next week then check for available slots in G
    if [[ $this_week == true || $next_week == true ]]; then
        echo "Checking G for: $(date -d @$curr_date '+%F (%A)')"
        # Execute the curl command and process the output
        result=$(curl -skb client_session=${cookie} ${url1} |
            grep -o '"time":[0-9]*' |
            grep -o '[0-9]*' |
            xargs -I {} date -d @{} |
            grep -E "(${convenient_hours}):")

        # Concatenate the result to a variable
        if [ -n "$result" ]; then
            echo "Found!"
            echo "G: $result"
            concatenated_result+=("G: $result ")
        fi
    fi

    # if curr_date is in this week or in 2 weeks then check for available slots in M
    if [[ true ]]; then

        echo "Checking M for: $(date -d @$curr_date '+%F (%A)')"
        # Execute the curl command and process the output
        result=$(curl -skb client_session=${cookie} ${url2} |
            grep -o '"time":[0-9]*' |
            grep -o '[0-9]*' |
            xargs -I {} date -d @{} |
            grep -E "(${convenient_hours}):")

        # Concatenate the result to a variable
        if [ -n "$result" ]; then
            echo "Found!"
            echo "M: $result"
            concatenated_result+=("M: $result ")
        fi
    fi
done

echo
echo "Available slots:"

for i in "${concatenated_result[@]}"; do
    echo "$i"
done
