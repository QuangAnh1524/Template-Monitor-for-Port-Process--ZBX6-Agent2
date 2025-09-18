#!/bin/bash
# Script: /etc/zabbix/scripts/check_https_content.sh
# Usage: check_https_content.sh <url> <pattern> [timeout]

URL="$1"
PATTERN="$2"
TIMEOUT="${3:-10}"

if [ -z "$URL" ] || [ -z "$PATTERN" ]; then
    echo "Usage: $0 <url> <pattern> [timeout]"
    exit 1
fi

# check va them https neu can
if [[ ! "$URL" =~ ^https?:// ]]; then
    URL="https://$URL"
fi

# lay noi dung web voi timeout
#CONTENT=$(curl -s --max-time "$TIMEOUT" --insecure "$URL" 2>/dev/null)
CONTENT=$(curl -s --max-time "$TIMEOUT" --insecure --ciphers 'DEFAULT:!DH' --tls-max 1.2 "$URL" 2>/dev/null)
# check curl
if [ $? -ne 0 ]; then
    echo "0"  # 0 knoi dc
    exit 0
fi

# Tìm pattern trong nội dung
if echo "$CONTENT" | grep -q "$PATTERN"; then
    echo "1"  # Tìm thấy pattern
else
    echo "2"  # Không tìm thấy pattern
fi