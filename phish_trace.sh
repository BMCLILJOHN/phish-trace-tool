#!/bin/bash

# Usage check
if [ -z "$1" ]; then
  echo "Usage: $0 <domain.com | IP>"
  exit 1
fi

INPUT=$1

# Check if input is an IP (digits and dots only)
if [[ "$INPUT" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  IP=$INPUT
  DOMAIN=""
  echo "[*] IP address provided directly: $IP"
else
  DOMAIN=$INPUT
  echo "[*] Resolving IP address for domain: $DOMAIN"
  IP=$(dig +short $DOMAIN | tail -n 1)

  if [ -z "$IP" ]; then
    echo "[!] Could not resolve domain. Running WHOIS on domain only..."
    echo ""
    whois $DOMAIN | grep -Ei 'Domain Name|Registrar|Registrant|Creation Date|Expiry|Updated'
    echo ""
    echo "Done."
    exit 0
  fi

  echo "[+] Resolved IP: $IP"
fi

echo ""

# WHOIS Lookup
if [ ! -z "$DOMAIN" ]; then
  echo "[*] WHOIS on domain ($DOMAIN):"
  whois $DOMAIN | grep -Ei 'Domain Name|Registrar|Registrant|Creation Date|Expiry|Updated'
  echo ""
fi

echo "[*] WHOIS on IP ($IP):"
whois $IP | grep -Ei 'OrgName|NetRange|Country|CIDR|Abuse|Owner'
echo ""

# Nmap scan
echo "[*] Running Nmap scan on $IP..."
nmap -sV -Pn $IP
echo ""

# AbuseIPDB & Shodan
echo "[*] AbuseIPDB report for $IP:"
echo "    https://abuseipdb.com/check/$IP"

echo "[*] Shodan lookup for $IP:"
echo "    https://www.shodan.io/host/$IP"

echo ""
echo "✅ Scan complete."
