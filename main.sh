#!/bin/bash

# Get the cookie from the file
cookie="<YOUR_SESSION_TOKEN>"

# url1
base_url="<BASE_URL>"
const_url1="${base_url}<URL1_CUSTOM>"
const_url2="${base_url}<URL1_CUSTOM>"
param="<CUSTOM_PARAM>"


# Initialize the start date to today
start_date=$(date +%s)
dates=();

# Loop for the next 14 days
for i in $(seq 0 14); do
    # Calculate the Unix timestamp for the next day
    next_day_timestamp=$((start_date + i * 86400))
    
    # Format the timestamp as a human-readable date
    readable_date=$(date -d @$next_day_timestamp '+%F (%A)')
    
    # Print the Unix timestamp and the corresponding date
    # echo "Day $i:"
    # echo "Timestamp: $next_day_timestamp"
    # echo "Readable Date: $readable_date"
    # echo ""
    dates+=($next_day_timestamp)
done

# echo ${dates[@]}

# Loop through each URL
for curr_date in "${dates[@]}"; do
    this_week=false
    next_week=false
    two_weeks_later=false

    # Get the current day of the week (1 = Monday, 7 = Sunday)
    current_day=$(date +%u)

    # Determine the start of the current week, the start of the next week, and the start of the week after that
    if (( current_day < 4 )); then
        # Today is before Thursday, so the current week starts on Monday
        current_week_start=$(date -d "this Monday" +%s)
        next_week_start=$((current_week_start + 604800)) # Start of the next week
        week_after_next_week_start=$((next_week_start + 604800)) # Start of the week after the next week
    else
        # Today is Thursday or later, so the current week starts on the previous Monday
        current_week_start=$(date -d "last Monday" +%s)
        next_week_start=$((current_week_start + 604800)) # Start of the next week
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
        # Execute the curl command and process the output
        # result=$(curl -skb client_session=${cookie} ${url1} | \
        #         grep -o '"time":[0-9]*' | \
        #         grep -o '[0-9]*' | \
        #         xargs -I {} date -d @{} | \
        #         grep -E '(09|10|17|18|19|20|21):')
                
        # Concatenate the result to a variable
        if [ -n "$result" ]; then
            concatenated_result+="G: $result "
        fi
    fi

    # if curr_date is in this week or in 2 weeks then check for available slots in M
    if [[ $this_week == true || $two_weeks_later == true ]]; then
        # Execute the curl command and process the output
        # result=$(curl -skb client_session=${cookie} ${url2} | \
        #         grep -o '"time":[0-9]*' | \
        #         grep -o '[0-9]*' | \
        #         xargs -I {} date -d @{} | \
        #         grep -E '(09|10|17|18|19|20|21):')
                
        # Concatenate the result to a variable
        if [ -n "$result" ]; then
            concatenated_result+="M: $result "
        fi
    fi

    echo "curr_date human readable: $(date -d @$curr_date '+%F (%A)')"
    echo "this week: $this_week"
    echo "next week: $next_week"
    echo "2 weeks later: $two_weeks_later"
done

# Print the concatenated result
echo "$concatenated_result"