#!/bin/bash

MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
cd $MY_PATH

rm T*

FILE="0.tests.json"

# Safety check: Ensure the file exists
if [[ ! -f "$FILE" ]]; then
    echo "Error: $FILE not found."
    exit 1
fi

echo "Starting test sequence. Press [CTRL+C] to stop."
echo "-----------------------------------------------"

source venv/bin/activate
python3 test_monitor.py
