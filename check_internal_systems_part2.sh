#!/bin/bash
# Script: /etc/zabbix/scripts/check_internal_systems_part2.sh
# Usage: check_internal_systems.sh <ip:port_or_url> <pattern> [timeout]
# Purpose: Generic script for checking any IP:PORT or URL

TARGET="$1"
PATTERN="$2"
TIMEOUT="${3:-10}"

if [ -z "$TARGET" ] || [ -z "$PATTERN" ]; then
    echo "Usage: $0 <ip:port_or_url> <pattern> [timeout]"
    echo "Examples:"
    echo "  $0 10.144.64.102:8080 welcome"
    echo "  $0 192.168.1.100:80 login"
    echo "  $0 http://internal.company.com dashboard"
    exit 1
fi

# xu ly url
URL="$TARGET"

# neu la ip:port thi them http://
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    URL="http://$TARGET"
# chua co http hoac https thi them http://
elif [[ ! "$TARGET" =~ ^https?:// ]]; then
    URL="http://$TARGET"
fi

# log de debug 
# echo "$(date): Checking $TARGET -> $URL for pattern: $PATTERN" >> /tmp/zabbix_check.log

# knoi
CONTENT=$(curl -s --max-time "$TIMEOUT" --connect-timeout 5 "$URL" 2>/dev/null)
CURL_EXIT_CODE=$?

# check ket noi
if [ $CURL_EXIT_CODE -ne 0 ]; then
    # log de debug
    # echo "$(date): Failed to connect to $URL, curl exit code: $CURL_EXIT_CODE" >> /tmp/zabbix_check.log
    echo "0"  # ko ket noi duoc
    exit 0
fi

# check noi dung co rong ko
if [ -z "$CONTENT" ]; then
    echo "2"  # ko co noi dung
    exit 0
fi

# tim pattern
if echo "$CONTENT" | grep -qi "$PATTERN"; then
    echo "1"  # tim thay
else
    echo "3"  # ko thay
fi

exit 0