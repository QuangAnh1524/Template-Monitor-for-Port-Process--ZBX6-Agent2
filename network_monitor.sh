#!/bin/bash
# Zabbix Network Connectivity Monitor Script
# Version: 1.0
# Compatible with: Zabbix 6.0
# Purpose: Monitor network connectivity from current server to destination IPs/Ports

# Script location: /etc/zabbix/scripts/network_monitor.sh
# Usage: network_monitor.sh <action> <target_ip> [port] [count] [timeout]
# Actions: ping, tcp_check, udp_check, response_time, packet_loss

ACTION="$1"
TARGET_IP="$2"
PORT="$3"
COUNT="${4:-5}"
TIMEOUT="${5:-5}"

# Validate inputs
if [[ -z "$ACTION" || -z "$TARGET_IP" ]]; then
    echo "Usage: $0 <action> <target_ip> [port] [count] [timeout]"
    echo "Actions: ping, tcp_check, udp_check, response_time, packet_loss, port_response_time"
    exit 1
fi

# Validate IP address format
if ! [[ $TARGET_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    # Check if it's a valid hostname
    if ! nslookup "$TARGET_IP" >/dev/null 2>&1; then
        echo "0"
        exit 1
    fi
fi

case "$ACTION" in
    "ping")
        # Basic ping connectivity check (1 = reachable, 0 = not reachable)
        if ping -c 1 -W "$TIMEOUT" "$TARGET_IP" >/dev/null 2>&1; then
            echo "1"
        else
            echo "0"
        fi
        ;;
    
    "response_time")
        # Get average response time in milliseconds
        RESULT=$(ping -c "$COUNT" -W "$TIMEOUT" "$TARGET_IP" 2>/dev/null | grep "avg" | awk -F'/' '{print $5}')
        if [[ -n "$RESULT" ]]; then
            # Convert to seconds for Zabbix
            echo "scale=6; $RESULT/1000" | bc -l
        else
            echo "0"
        fi
        ;;
    
    "packet_loss")
        # Get packet loss percentage
        RESULT=$(ping -c "$COUNT" -W "$TIMEOUT" "$TARGET_IP" 2>/dev/null | grep "packet loss" | awk '{print $6}' | sed 's/%//')
        if [[ -n "$RESULT" ]]; then
            echo "$RESULT"
        else
            echo "100"
        fi
        ;;
    
    "tcp_check")
        # TCP port connectivity check
        if [[ -z "$PORT" ]]; then
            echo "Error: Port required for tcp_check"
            exit 1
        fi
        
        # Use timeout command with netcat or telnet
        if command -v nc >/dev/null 2>&1; then
            if timeout "$TIMEOUT" nc -z "$TARGET_IP" "$PORT" >/dev/null 2>&1; then
                echo "1"
            else
                echo "0"
            fi
        elif command -v telnet >/dev/null 2>&1; then
            if timeout "$TIMEOUT" telnet "$TARGET_IP" "$PORT" >/dev/null 2>&1; then
                echo "1"
            else
                echo "0"
            fi
        else
            # Fallback using /dev/tcp (bash built-in)
            if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$TARGET_IP/$PORT" >/dev/null 2>&1; then
                echo "1"
            else
                echo "0"
            fi
        fi
        ;;
    
    "udp_check")
        # UDP port connectivity check (limited accuracy)
        if [[ -z "$PORT" ]]; then
            echo "Error: Port required for udp_check"
            exit 1
        fi
        
        if command -v nc >/dev/null 2>&1; then
            # Send empty packet and check if port responds
            if timeout "$TIMEOUT" nc -u -z "$TARGET_IP" "$PORT" >/dev/null 2>&1; then
                echo "1"
            else
                echo "0"
            fi
        else
            echo "0"
        fi
        ;;
    
    "port_response_time")
        # Measure TCP port response time
        if [[ -z "$PORT" ]]; then
            echo "Error: Port required for port_response_time"
            exit 1
        fi
        
        START_TIME=$(date +%s.%N)
        if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$TARGET_IP/$PORT" >/dev/null 2>&1; then
            END_TIME=$(date +%s.%N)
            RESPONSE_TIME=$(echo "$END_TIME - $START_TIME" | bc -l)
            echo "$RESPONSE_TIME"
        else
            echo "0"
        fi
        ;;
    
    "http_check")
        # HTTP/HTTPS connectivity and response code check
        PORT="${PORT:-80}"
        PROTOCOL="http"
        
        if [[ "$PORT" == "443" ]]; then
            PROTOCOL="https"
        fi
        
        if command -v curl >/dev/null 2>&1; then
            HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$TIMEOUT" "$PROTOCOL://$TARGET_IP:$PORT/" 2>/dev/null)
            if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 400 ]]; then
                echo "1"
            else
                echo "0"
            fi
        elif command -v wget >/dev/null 2>&1; then
            if timeout "$TIMEOUT" wget --spider --quiet "$PROTOCOL://$TARGET_IP:$PORT/" >/dev/null 2>&1; then
                echo "1"
            else
                echo "0"
            fi
        else
            echo "0"
        fi
        ;;
    
    *)
        echo "Invalid action. Available actions: ping, tcp_check, udp_check, response_time, packet_loss, port_response_time, http_check"
        exit 1
        ;;
esac

exit 0