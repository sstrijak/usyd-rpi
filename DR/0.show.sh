#!/bin/bash

JSON_FILE="0.tests.json"

# Check if the JSON file exists before starting
if [[ ! -f "$JSON_FILE" ]]; then
  echo "Error: $JSON_FILE not found." >&2
  exit 1
fi

# --- OPTIMIZATION: Read JSON file ONCE here ---
# Reads the data into a Bash array. Each element will look like: "ID:TAG"
mapfile -t TEST_LIST < <(jq -r '.[] | "\(.id):\(.tag)"' "$JSON_FILE")

while true; do
  clear # Optional: clears the screen for a cleaner "dashboard" look
  date | tee -a 3.show.log
  
  printf "%-5s %-20s %6s\n" "ID" "Target Tag" "Age(s)"
  echo "------------------------------------------"

  # Loop over the array kept in memory instead of reading the file
  CTIME=`date +%s` 
  for item in "${TEST_LIST[@]}"; do
    # Split the "ID:TAG" string back into separate variables
    id="${item%%:*}"
    tag="${item#*:}"
    LTIME=0
    if [[ -f "$id" ]]; then LTIME=$(head -n 1 $id); fi
    DTIME=$((CTIME - ${LTIME:-0}))
    printf "%4s %20s %3s\n" $id $tag $DTIME    
    printf "%4s %20s %3s\n" $id $tag $DTIME >> 3.show.log
  done

  sleep 3s
done
