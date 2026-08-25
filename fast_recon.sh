#!/bin/bash

# Ensure an IP address argument was provided
if [ -z "$1" ]; then
    echo "[-] Usage: $0 <Target-IP>"
    exit 1
fi

TARGET_IP="$1"
OUTPUT_DIR="./recon_$TARGET_IP"
mkdir -p "$OUTPUT_DIR"

echo "[*] Target Identified: $TARGET_IP"
echo "[*] Results will be saved to: $OUTPUT_DIR"
echo "--------------------------------------------------"

# Step 1: Perform a high-speed initial port scan for top 1000 ports
echo "[+] Launching high-speed initial Nmap scan..."
NMAP_FAST="$OUTPUT_DIR/nmap_fast.txt"
sudo nmap -T4 --top-ports 1000 "$TARGET_IP" -oG "$NMAP_FAST" > /dev/null

# Extract all open ports from grepable output for summary display
OPEN_PORTS=$(grep "Ports:" "$NMAP_FAST" | grep -oE '[0-9]+/open' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

if [ -z "$OPEN_PORTS" ]; then
    echo "[-] No open ports found in top 1000 list. Exiting."
    exit 1
fi

echo "[+] Open ports discovered: $OPEN_PORTS"
echo "--------------------------------------------------"
echo "[*] Triggering contextual enumeration tools in parallel..."

# Helper tracking flags
HTTP_FOUND=false
SMB_FOUND=false

# Check for Web Services (Port 80, 443, 8080)
if grep -qE "80/open|443/open|8080/open" "$NMAP_FAST"; then
    HTTP_FOUND=true
    echo "[-->] [WEB] Web service detected! Starting background directory busting..."
    # Launch GoBuster background process using a standard directory wordlist
    gobuster dir -u "http://$TARGET_IP" -w /usr/share/wordlists/dirb/common.txt -q -o "$OUTPUT_DIR/gobuster_results.txt" &
fi

# Check for SMB Services (Port 139, 445)
if grep -qE "139/open|445/open" "$NMAP_FAST"; then
    SMB_FOUND=true
    echo "[-->] [SMB] SMB service detected! Starting background share enumeration..."
    # Attempt an anonymous login or listing via smbclient in the background
    smbclient -L "//$TARGET_IP/" -N > "$OUTPUT_DIR/smb_shares.txt" 2>&1 &
fi

# Fallback catch-all detailed version scan runs concurrently 
echo "[+] Starting intensive background service/version detection (-sV -sC)..."
sudo nmap -sC -sV -p "$OPEN_PORTS" "$TARGET_IP" -oN "$OUTPUT_DIR/nmap_detailed.txt" > /dev/null &

# Wait for all background multi-threaded tasks to complete execution
echo "[*] Waiting for background threads to finish processing..."
wait

echo "--------------------------------------------------"
echo "[+] Automation routine complete! Review outputs in: $OUTPUT_DIR"
if [ "$HTTP_FOUND" = true ]; then echo "    -> Web Dirb Results: $OUTPUT_DIR/gobuster_results.txt"; fi
if [ "$SMB_FOUND" = true ]; then echo "    -> SMB Share Results: $OUTPUT_DIR/smb_shares.txt"; fi
echo "    -> Detailed Nmap Scan: $OUTPUT_DIR/nmap_detailed.txt"
