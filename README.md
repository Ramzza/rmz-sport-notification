# rmz-sport-notification

Sends notifications for freed up sport slots

## Reserve a slot for a specific date and time

Usage: ./targeted_reservation --cookie <cookie> --location <MON|GHE> --date <YYYY-MM-DD> [--time <HH:MM>]

## Set up a cron job for reserving the given time in two weeks

crontab -e

<MM> <HH> \* \* <NUMBER_OF_WEEKDAY> <PATH_TO_PROJECT_FOLDER>/targeted_reservation.sh --cookie <cookie> --location <MON|GHE> --time "<HH:MM>"
