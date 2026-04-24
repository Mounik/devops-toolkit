#!/bin/bash
# health-check.sh — Comprehensive server health report
# Usage: ./health-check.sh [output_format]
#   output_format: text (default), json

set -euo pipefail

FORMAT="${1:-text}"

REPORT_DATA=()

collect() {
    local label=$1
    local value=$2
    if [[ "$FORMAT" == "json" ]]; then
        REPORT_DATA+=("\"$label\": \"$value\"")
    else
        printf "%-30s %s\n" "$label:" "$value"
    fi
}

if [[ "$FORMAT" != "json" ]]; then
    echo "========================================="
    echo "  SERVER HEALTH REPORT — $(date)"
    echo "========================================="
    echo ""
fi

# System
collect "Hostname" "$(hostname)"
collect "Uptime" "$(uptime -p)"
collect "Kernel" "$(uname -r)"
collect "OS" "$(grep PRETTY_NAME < /etc/os-release 2>/dev/null | cut -d'"' -f2 || uname -s)"

# CPU
collect "CPU Model" "$(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
collect "CPU Cores" "$(nproc)"
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%
collect "CPU Usage" "$cpu_usage"
collect "Load Average" "$(awk '{print $1, $2, $3}' /proc/loadavg)"

# Memory
collect "Total RAM" "$(free -h | awk '/Mem:/ {print $2}')"
collect "Used RAM" "$(free -h | awk '/Mem:/ {print $3}')"
collect "Available RAM" "$(free -h | awk '/Mem:/ {print $7}')"
collect "Swap Used" "$(free -h | awk '/Swap:/ {print $3}')"

# Disk
if [[ "$FORMAT" != "json" ]]; then
    echo ""
    echo "=== Disk Usage ==="
    df -h --type=ext4 --type=xfs --type=btrfs 2>/dev/null | awk '{printf "%-20s %8s %8s %8s %s\n", $1, $2, $3, $4, $5}'
fi

# Network
collect "Public IP" "$(curl -s4 ifconfig.me 2>/dev/null || echo 'unavailable')"
collect "Listening Ports" "$(ss -tlnp | tail -n +2 | wc -l)"

# Docker
if command -v docker &>/dev/null; then
    collect "Docker" "installed"
    collect "Running Containers" "$(docker ps -q | wc -l)"
    collect "Stopped Containers" "$(docker ps -q --filter status=exited | wc -l)"
    collect "Docker Disk Usage" "$(docker system df --format '{{.Size}}' | head -1)"
else
    collect "Docker" "not installed"
fi

# Services status
if [[ "$FORMAT" != "json" ]]; then
    echo ""
    echo "=== Failed Services ==="
    systemctl --failed --no-legend 2>/dev/null || echo "No failed services"
fi

# Security
collect "UFW Status" "$(ufw status 2>/dev/null | head -1 || echo 'not installed')"
collect "Fail2ban" "$(systemctl is-active fail2ban 2>/dev/null || echo 'not running')"
collect "Last Login" "$(last -1 -w 2>/dev/null | head -1 || echo 'n/a')"

# Reboot needed?
if [[ -f /var/run/reboot-required ]]; then
    collect "Reboot Required" "YES"
else
    collect "Reboot Required" "no"
fi

# Pending updates
if command -v apt &>/dev/null; then
    collect "Pending Updates" "$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)"
    collect "Security Updates" "$(apt list --upgradable 2>/dev/null | grep -ci security || echo 0)"
fi

if [[ "$FORMAT" == "json" ]]; then
    echo "{"
    for i in "${!REPORT_DATA[@]}"; do
        if [[ $i -eq $((${#REPORT_DATA[@]} - 1)) ]]; then
            echo "  ${REPORT_DATA[$i]}"
        else
            echo "  ${REPORT_DATA[$i]},"
        fi
    done
    echo "}"
else
    echo ""
    echo "========================================="
fi