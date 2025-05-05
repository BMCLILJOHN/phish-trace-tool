#!/bin/bash

# Check if domain was provided
if [ -z "$1" ]; then
  echo "Usage: $0 domain.com"
  exit 1
fi

DOMAIN=$1
echo "[*] Resolving IP address for: $DOMAIN"

# Resolve IP address
IP=$(dig +short $DOMAIN | tail -n 1)

if [ -z "$IP" ]; then
  echo "[!] Could not resolve domain."
  exit 2
fi

echo "[+] Resolved IP: $IP"

# Run basic nmap scan
echo "[*] Running Nmap scan on $IP..."
nmap -sV -Pn $IP

# Optional: Show AbuseIPDB lookup URL
echo ""
echo "[*] Check abuse reports for $IP here:"
echo "    https://abuseipdb.com/check/$IP"
echo ""
echo "Done."
