#!/usr/bin/env zsh
# Roughly calculate the date after N business days.
#
# Does not take holidays into account.
#
# SYNOPSIS:
#   hey .bday 5

if [[ -z "$1" ]]; then
  echo "Usage: $0 <business_days>"
  exit 1
fi

N=$1
today=$(date +%Y-%m-%d)

while [ $N -gt 0 ]; do
  # move forward by one day
  today=$(date -I -d "$today + 1 day")

  # check if it's a weekday (Mon=1..Fri=5)
  day_of_week=$(date -d "$today" +%u)
  if [ "$day_of_week" -lt 6 ]; then
    N=$((N - 1))
  fi
done

echo "Resulting date: $today"
