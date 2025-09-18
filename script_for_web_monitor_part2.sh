#!/bin/bash
# Script: /etc/zabbix/scripts/check_internal_systems.sh
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

# Xử lý URL
URL="$TARGET"

# Nếu là IP:PORT, thêm http://
if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    URL="http://$TARGET"
# Nếu chưa có protocol, thêm http://
elif [[ ! "$TARGET" =~ ^https?:// ]]; then
    URL="http://$TARGET"
fi

# Log debug (uncomment nếu cần)
# echo "$(date): Checking $TARGET -> $URL for pattern: $PATTERN" >> /tmp/zabbix_check.log

# Thực hiện kết nối
CONTENT=$(curl -s --max-time "$TIMEOUT" --connect-timeout 5 "$URL" 2>/dev/null)
CURL_EXIT_CODE=$?

# Kiểm tra kết nối
if [ $CURL_EXIT_CODE -ne 0 ]; then
    # Log lỗi (uncomment nếu cần debug)
    # echo "$(date): Failed to connect to $URL, curl exit code: $CURL_EXIT_CODE" >> /tmp/zabbix_check.log
    echo "0"  # Không kết nối được
    exit 0
fi

# Kiểm tra nội dung có rỗng không
if [ -z "$CONTENT" ]; then
    echo "2"  # Không có nội dung
    exit 0
fi

# Tìm pattern trong nội dung (case insensitive)
if echo "$CONTENT" | grep -qi "$PATTERN"; then
    echo "1"  # Tìm thấy pattern
else
    echo "3"  # Không tìm thấy pattern
fi

exit 0