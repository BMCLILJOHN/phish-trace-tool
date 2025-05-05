#!/bin/bash

clear
echo "====== Phishing Domain Trace Tool ======"
read -p "Enter a domain, phishing URL, or email address: " INPUT

# Extract domain from email or URL
if [[ "$INPUT" =~ @ ]]; then
    DOMAIN=$(echo "$INPUT" | awk -F'@' '{print $2}')
elif [[ "$INPUT" =~ https?:// ]]; then
    DOMAIN=$(echo "$INPUT" | awk -F[/:] '{print $4}')
else
    DOMAIN="$INPUT"
fi

echo -e "\n[*] Analyzing domain: $DOMAIN"

# WHOIS lookup
echo -e "\n====== WHOIS INFO ======"
WHOIS=$(whois "$DOMAIN")
echo "$WHOIS"

# Domain creation date
CREATED=$(echo "$WHOIS" | grep -iE 'Creation Date:|created:' | head -n 1 | awk '{print $NF}')
if [[ -n "$CREATED" ]]; then
    CREATED_DATE=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CREATED" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$CREATED" +%s 2>/dev/null)
    TODAY=$(date +%s)
    AGE_DAYS=$(( (TODAY - CREATED_DATE) / 86400 ))
    echo -e "\n[*] Domain age: $AGE_DAYS days"
    if (( AGE_DAYS < 7 )); then
        echo "⚠️  Very new domain — likely burner or suspicious."
    fi
else
    echo "⚠️  Could not determine domain creation date."
fi

# DNS lookups
echo -e "\n====== DNS RECORDS ======"
echo -e "\n[+] A Record:"
A_RECORD=$(dig +short A "$DOMAIN")
echo "$A_RECORD"

echo -e "\n[+] MX Records:"
dig +short MX "$DOMAIN"

echo -e "\n[+] TXT Records (SPF/DKIM/DMARC):"
dig +short TXT "$DOMAIN"

# Abuse contact
echo -e "\n====== ABUSE REPORT TEMPLATE ======"
REGISTRAR=$(echo "$WHOIS" | grep -i "Registrar:" | head -n 1 | awk -F: '{print $2}' | xargs)
ABUSE_EMAIL=$(echo "$WHOIS" | grep -i "Abuse Contact Email:" | head -n 1 | awk -F: '{print $2}' | xargs)
[[ -z "$ABUSE_EMAIL" ]] && ABUSE_EMAIL="(Could not auto-detect)"

cat <<EOF

To: $ABUSE_EMAIL
Subject: URGENT: Phishing domain used in scam – $DOMAIN

Hello,

I received a phishing message referencing the domain $DOMAIN, which appears to be newly registered and is being used for fraud. The domain lacks email authentication records (SPF/DKIM/DMARC), and exhibits burner domain behavior.

Please investigate and suspend the domain.

Thank you,
[Your Name]
EOF

# Reputation tools
echo -e "\n====== QUICK REPUTATION LINKS ======"
echo "🔗 VirusTotal: https://www.virustotal.com/gui/domain/$DOMAIN"
echo "🔗 URLScan:    https://urlscan.io/search/#$DOMAIN"
echo "🔗 AbuseIPDB:  https://abuseipdb.com/whois/$DOMAIN"
echo "🔗 Talos:      https://talosintelligence.com/reputation_center/lookup?search=$DOMAIN"

# Nmap scan
if [[ -n "$A_RECORD" ]]; then
    echo -e "\n====== OPTIONAL: NMAP SCAN ======"
    read -p "Would you like to run a basic Nmap scan on $A_RECORD? (y/n): " NMAP_CHOICE
    if [[ "$NMAP_CHOICE" =~ ^[Yy]$ ]]; then
        echo -e "\n[*] Running Nmap scan..."
        nmap -F -Pn "$A_RECORD"
    else
        echo "[*] Skipping Nmap scan."
    fi
else
    echo -e "\n[!] No A record found — cannot perform Nmap scan."
fi

echo -e "\n✅ Done."
