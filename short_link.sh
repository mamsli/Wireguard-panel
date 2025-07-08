#!/bin/bash
# =============================================================================
#  Update Short Links Base URL Script
#
#  This script updates the base URL (protocol, domain/IP, and port) in the
#  short_links.json file located at /usr/local/bin/Wireguard-panel/src/.
#
#  It performs the following tasks:
#    - If both short_links.json and short_links_decrypted.json exist, removes
#      short_links.json and renames short_links_decrypted.json to short_links.json.
#    - Verifies that the target JSON file exists.
#    - Checks if jq is installed; if not, attempts to install it automatically.
#    - Prompts the user for the new protocol (default is https), domain/IP, and port.
#    - Uses jq to replace the base URL in every entry within the JSON file.
#
#  NOTE: You may need sudo privileges for installing jq and updating the file.
# =============================================================================

RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"  

FILE="/usr/local/bin/Wireguard-panel/src/short_links.json"
DECRYPTED_FILE="/usr/local/bin/Wireguard-panel/src/short_links_decrypted.json"

if [[ -f "$DECRYPTED_FILE" && -f "$FILE" ]]; then
    echo -e "${BLUE}Both ${FILE} and ${DECRYPTED_FILE} exist.${NC}"
    echo -e "${BLUE}Removing ${FILE} and renaming ${DECRYPTED_FILE} to ${FILE}.${NC}"
    rm "$FILE"
    mv "$DECRYPTED_FILE" "$FILE"
fi

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: File $FILE not found.${NC}"
    exit 1
fi

install_jq() {
    echo -e "${BLUE}jq is required but not installed. installing jq...${NC}"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y jq
    elif command -v brew >/dev/null 2>&1; then
        brew install jq
    else
        echo -e "${RED}No supported package found. Please install jq manually.${NC}"
        exit 1
    fi
}

if ! command -v jq >/dev/null 2>&1; then
    install_jq
    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${RED}Couldn't install jq. Please install it manually.${NC}"
        exit 1
    else
        echo -e "${GREEN}jq installed successfully.${NC}"
    fi
fi

read -p "$(echo -e ${YELLOW}"Enter new protocol ${GREEN}(http or https,${YELLOW} default: https): "${NC})" PROTOCOL
if [ -z "$PROTOCOL" ]; then
    PROTOCOL="https"
fi
if [[ "$PROTOCOL" != "http" && "$PROTOCOL" != "https" ]]; then
    echo -e "${RED}Invalid protocol. Only 'http' or 'https' are allowed.${NC}"
    exit 1
fi

read -p "$(echo -e ${YELLOW}"Enter new domain ${GREEN}(e.g., 198.198.198.198 ${YELLOW}or azumi.com): "${NC})" NEW_DOMAIN
if [ -z "$NEW_DOMAIN" ]; then
    echo -e "${RED}Domain or IP cannot be empty.${NC}"
    exit 1
fi

read -p "$(echo -e ${YELLOW}"Enter ${GREEN}new port${YELLOW} (e.g, 8843): "${NC})" NEW_PORT
if [ -z "$NEW_PORT" ]; then
    echo -e "${RED}Port cannot be empty.${NC}"
    exit 1
fi

NEW_BASE_URL="${PROTOCOL}://$NEW_DOMAIN:$NEW_PORT"
echo -e "${BLUE}New base URL set to: ${GREEN}$NEW_BASE_URL${NC}"

echo -e "${BLUE}Updating URLs in ${FILE}...${NC}"
if jq --arg new_base_url "$NEW_BASE_URL" 'with_entries(.value |= sub("https?://[^/]+"; $new_base_url))' "$FILE" > "${FILE}.tmp"; then
    mv "${FILE}.tmp" "$FILE"
    echo -e "${GREEN}Successfully updated short_links.json with new base URL: $NEW_BASE_URL${NC}"
else
    echo -e "${RED}Couldn't update the JSON file.${NC}"
    exit 1
fi
