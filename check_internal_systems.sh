#!/bin/bash
# Script: /etc/zabbix/scripts/check_internal_systems.sh
# Usage: check_internal_systems.sh <system_name> <pattern> [timeout]
# Purpose: Check internal network systems connectivity and content

SYSTEM_NAME="$1"
PATTERN="$2"
TIMEOUT="${3:-10}"

if [ -z "$SYSTEM_NAME" ] || [ -z "$PATTERN" ]; then
    echo "Usage: $0 <system_name> <pattern> [timeout]"
    echo "Available systems: ABC, APP1, APP2, APP3, APP4, APP5"
    exit 1
fi

# Mapping hệ thống nội bộ
case "$SYSTEM_NAME" in
    "ABC"|"abc")
        URL="http://10.144.20.100:80"
        ;;
    "SYSTEM2"|"system2")
        URL="http://10.144.20.101:80"
        ;;
    "APP1"|"app1")
        URL="http://10.144.64.102:8080"
        ;;
    "APP2"|"app2")
        URL="http://10.144.64.102:8081"
        ;;
    "APP3"|"app3")
        URL="http://10.144.64.102:9696"
        ;;
    "APP4"|"app4")
        URL="http://10.144.64.102:80"
        ;;
    "APP5"|"app5")
        URL="http://10.144.64.102:9697"
        ;;
    *)
        # Nếu truyền trực tiếp IP:PORT
        if [[ "$SYSTEM_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
            URL="http://$SYSTEM_NAME"
        else
            echo "Unknown system: $SYSTEM_NAME"
            exit 1
        fi
        ;;
esac

# Log để debug (có thể bỏ comment nếu cần)
# echo "Checking URL: $URL for pattern: $PATTERN" >> /tmp/zabbix_check.log

# Thực hiện kết nối và lấy nội dung
CONTENT=$(curl -s --max-time "$TIMEOUT" --connect-timeout 5 "$URL" 2>/dev/null)
CURL_EXIT_CODE=$?

# Kiểm tra kết nối có thành công không
if [ $CURL_EXIT_CODE -ne 0 ]; then
    # Log lỗi nếu cần debug
    # echo "$(date): Failed to connect to $URL, curl exit code: $CURL_EXIT_CODE" >> /tmp/zabbix_check.log
    echo "0"  # Không kết nối được
    exit 0
fi

# Kiểm tra nội dung có rỗng không
if [ -z "$CONTENT" ]; then
    echo "2"  # Không có nội dung
    exit 2
fi

# Tìm pattern trong nội dung (case insensitive)
if echo "$CONTENT" | grep -qi "$PATTERN"; then
    echo "1"  # Tìm thấy pattern
else
    echo "3"  # Không tìm thấy pattern
fi

exit 5