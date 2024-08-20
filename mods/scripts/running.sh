#!/bin/bash

# ANSI color codes for green, red, blue, and orange
GREEN="\033[0;32m"
RED="\033[0;31m"
BLUE="\033[0;34m"
ORANGE="\033[0;33m"
NC="\033[0m" # No color

# Source the apps_interface function from the external script
source /pg/scripts/apps_interface

# Clear the screen at the start
clear

# Terminal width and maximum character length per line
TERMINAL_WIDTH=80
MAX_LINE_LENGTH=72

# Function to list running Docker apps, excluding cf_tunnel
list_running_docker_apps() {
    docker ps --format '{{.Names}}' | grep -v 'cf_tunnel' | sort
}

# Function to display running Docker apps in a formatted way
display_running_apps() {
    local apps_list=("$@")
    local current_line=""
    local current_length=0

    for app in "${apps_list[@]}"; do
        local app_length=${#app}
        local new_length=$((current_length + app_length + 1)) # +1 for the space

        # If adding the app would exceed the maximum length, start a new line
        if [[ $new_length -gt $TERMINAL_WIDTH ]]; then
            echo "$current_line"
            current_line="$app "
            current_length=$((app_length + 1)) # Reset with the new app and a space
        else
            current_line+="$app "
            current_length=$new_length
        fi
    done

    # Print the last line if it has content
    if [[ -n $current_line ]]; then
        echo "$current_line"
    fi
}

# Function to deploy the selected app
deploy_app() {
    local app_name=$1
    local app_path="/pg/apps/$app_name"

    # Call the apps_interface function
    apps_interface "$app_name"
}

# Main running function
running_function() {
    while true; do
        clear

        # Get the list of running Docker apps, excluding cf_tunnel
        APP_LIST=($(list_running_docker_apps))

        if [[ ${#APP_LIST[@]} -eq 0 ]]; then
            clear
            echo -e "${RED}Cannot View/Edit Apps as None Exist.${NC}"
            echo ""  # Blank line for separation
            read -p "$(echo -e "${RED}Press Enter to continue...${NC}")"
            exit 0
        fi

        echo -e "${RED}PG: Running Apps [View | Edit]${NC}"
        echo ""  # Blank line for separation

        # Display the list of running Docker apps, excluding cf_tunnel
        display_running_apps "${APP_LIST[@]}"
        
        echo "════════════════════════════════════════════════════════════════════════════════"
        # Prompt the user to enter an app name or exit
        read -p "$(echo -e "Type [${GREEN}App${NC}] to View/Edit or [${RED}Exit${NC}]: ")" app_choice

        # Convert the user input to lowercase for case-insensitive matching
        app_choice=$(echo "$app_choice" | tr '[:upper:]' '[:lower:]')

        # Check if the user wants to exit
        if [[ "$app_choice" == "exit" ]]; then
            exit 0
        fi

        # Check if the app exists in the list of running Docker apps (case-insensitive)
        if echo "${APP_LIST[@]}" | grep -i -w "$app_choice" >/dev/null; then
            # Deploy the selected app by calling the apps_interface function
            deploy_app "$app_choice"
        else
            echo "Invalid choice. Please try again."
            read -p "Press Enter to continue..."
        fi
    done
}

# Call the main running function
running_function
