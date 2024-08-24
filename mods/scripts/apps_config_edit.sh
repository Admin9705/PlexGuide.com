#!/bin/bash

# ANSI color codes
RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m" # No color

app_name=$1
config_path="/pg/config/$app_name.cfg"

clear
edit_code=$(printf "%04d" $((RANDOM % 10000)))

echo -e "${RED}Warning: This is an advanced option.${NC}"
echo "Visit https://plexguide.com/wiki/link-not-set for more information."
echo ""
echo "This will allow you to modify the current config file."
echo "The Docker container will be stopped and removed if running."
echo "You must deploy the Docker container again to accept your changes."
echo ""
echo -e "Do you want to proceed? Type [${RED}${edit_code}${NC}] to proceed or [${GREEN}no${NC}] to cancel: "

while true; do
    read -p "" edit_choice
    if [[ "$edit_choice" == "$edit_code" ]]; then
        # Capture file's modification time before editing
        before_edit=$(stat -c %Y "$config_path")

        nano "/pg/config/$app_name.cfg"

        # Capture file's modification time after editing
        after_edit=$(stat -c %Y "$config_path")

        # Check if the config file was modified
        if [[ "$before_edit" != "$after_edit" ]]; then
            # Stop and remove the Docker container if running
            docker ps --filter "name=^/${app_name}$" --format "{{.Names}}" &> /dev/null
            if [[ $? -eq 0 ]]; then
                echo ""
                echo "Stopping and removing the existing container for $app_name ..."
                docker stop "$app_name" && docker rm "$app_name"
            else
                echo "Container $app_name is not running."
            fi
        else
            echo "No changes detected in the config file. No need to stop the container."
        fi

        break
    elif [[ "${edit_choice,,}" == "no" ]]; then
        echo "Operation cancelled."
        break
    else
        echo -e "${RED}Invalid response.${NC} Please type [${RED}${edit_code}${NC}] or [${GREEN}no${NC}]."
    fi
done
