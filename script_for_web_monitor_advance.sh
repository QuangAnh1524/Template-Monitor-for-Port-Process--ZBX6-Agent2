#!/bin/bash
# Script: /etc/zabbix/scripts/script_for_web_monitor_advance.sh
# Usage: script_for_web_monitor_advance.sh <url> <pattern> [timeout] [mode]
# Mode: content, status, response_time

URL="$1"
PATTERN="$2"
TIMEOUT="${3:-10}"
MODE="${4:-content}"


if [ -z "$URL" ] || [ -z "$PATTERN" ] ; then
    echo "Usage: $0 <url> <pattern> [timeout] [mode]"
    echo "Modes:"
    echo "  content       - Check if pattern exists (returns 1/0)"
    echo "  status        - Return HTTP status code (200, 404, 500...)"
    echo "  response_time - Return response time in seconds"
    exit 1
fi

# check va them https neu can
if [[ ! "$URL" =~ ^https?:// ]]; then
    URL="https://$URL"
fi

# curl, lay theo mode
case "$MODE" in
    "content")
        # lay noi dung check pattern
        CONTENT=$(curl -s --max-time "$TIMEOUT" --insecure --ciphers 'DEFAULT:!DH' --tls-max 1.2 "$URL" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "0"  # ko ket noi duoc
            exit 0
        fi
        
        # tim pattern
        if echo "$CONTENT" | grep -q "$PATTERN"; then
            echo "1"  # tim thay
        else
            echo "0"  # ko tim thay
        fi
        ;;
        
    "status")
        # lay status code
        STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" --insecure --ciphers 'DEFAULT:!DH' --tls-max 1.2 "$URL" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "0"  # ko ket noi duoc
        else
            echo "$STATUS_CODE"  
        fi
        ;;
        
    "response_time")
        # lay res time total
        RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" --max-time "$TIMEOUT" --insecure --ciphers 'DEFAULT:!DH' --tls-max 1.2 "$URL" 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo "0"  # ko ket noi duoc
        else
            echo "$RESPONSE_TIME"  
        fi
        ;;
        
    *)
        echo "Invalid mode: $MODE"
        echo "Available modes: content, status, response_time"
        exit 1
        ;;
esac

exit 0