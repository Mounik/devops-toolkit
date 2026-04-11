#!/bin/bash
# ssl-check.sh — Check SSL certificate expiry for domains
# Usage: ./ssl-check.sh example.com [days_warning]
#   days_warning: alert if cert expires within N days (default: 30)

set -euo pipefail

DOMAIN="${1:?Usage: $0 domain [days_warning]}"
WARN_DAYS="${2:-30}"

check_cert() {
    local domain=$1
    local port=443

    local expiry
    expiry=$(echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)

    if [[ -z "$expiry" ]]; then
        echo "❌ $domain — Could not retrieve certificate"
        return 1
    fi

    local expiry_epoch now_epoch days_left
    expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || date -j -f "%b %d %T %Y %Z" "$expiry" +%s)
    now_epoch=$(date +%s)
    days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [[ $days_left -le 0 ]]; then
        echo "🔴 $domain — EXPIRED ($days_left days)"
    elif [[ $days_left -le $WARN_DAYS ]]; then
        echo "🟡 $domain — Expires in $days_left days (expiry: $expiry)"
    else
        echo "🟢 $domain — OK ($days_left days remaining, expires: $expiry)"
    fi
}

check_cert "$DOMAIN"