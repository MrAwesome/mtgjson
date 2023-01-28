#!/bin/bash

set -euo pipefail

which jq >/dev/null 2>&1 || { echo "jq not found"; exit 1; }
which curl >/dev/null 2>&1 || { echo "curl not found"; exit 1; }

cd "$(dirname "$0")"

jsonfile="AtomicCards.json"
txtfile="AtomicCards.txt"

datadir="data"

mkdir -p "${datadir}"
cd "${datadir}"

# Set up command line arguments:
fullinfo=false
clean=false
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--clean)
            clean=true
            shift
            ;;
        -f|--fullinfo)
            fullinfo=true
            shift
            ;;
        *)
            echo "Unknown argument: $key"
            exit 1
            ;;
    esac
done

if [ "${clean}" = true ]; then
    echo "[INFO] Cleaning up data files..."
    rm -f "${jsonfile}" "${txtfile}"
    exit 0
fi

# If the json file doesn't exist or is empty, download it
if [ ! -f "${jsonfile}" ] || [ ! -s "${jsonfile}" ]; then
    echo "[INFO] Doing initial fetch of JSON data for cards..."
    curl "https://mtgjson.com/api/v5/${jsonfile}" -o "${jsonfile}"
fi

# If the txt file doesn't exist or is empty, create it by parsing the json file and pulling out only 
#   the fields we want, tab separated, and saving to the txt file
if [ ! -f "${txtfile}" ] || [ ! -s "${txtfile}" ]; then
    echo "[INFO] Doing initial processing of JSON data for cards..."
    jq -r '.data[][] | [.name, .manaCost, .type, .text] | @tsv' > "${txtfile}" < "${jsonfile}"
fi

# Use fzf to search, and then use awk to print the card's info, with each field separated by a tab.
#   As of Jan 2023, there are no tab characters in any card fields, so this is safe enough for now.
selected_card_info=$(fzf < "${txtfile}")

# If the -f/--fullinfo argument was passed, grab the full info for the selected card
if [ "${fullinfo}" = true ]; then
    selected_card_name=$(echo "${selected_card_info}" | awk -F'	' '{print $1}')
    selected_card_full_info=$(jq -r --arg name "${selected_card_name}" '.data[][] | select(.name == $name)' < "${jsonfile}")
    echo "${selected_card_full_info}" | jq
else
    # Otherwise, just print out the info we already have.
    echo "${selected_card_info}" | \
        # Put the mana cost on the same line as the name
        sed -E 's/	/    /' | \
        # Display the rest separated by newlines. Also display newlines as they are in the card text.
        sed -E 's/(	|\\n)/\n/g'
fi
