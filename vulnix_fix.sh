#!/bin/bash
#
# vulnix_fix.sh - Script to harden Vulnix-VM
# Author: Robin | Cybetrsteps - Modul 2 - Project 5
# Run as root on the Vulnix-VM
#

set -euo pipefail          # break on error

echo "=== Start: Hardening Vulnix ==="
echo "[ ] Step 1 - backup files"
echo "[ ] Step 2 - disable fingerd and r-services"
echo "[ ] Step 3 - deactivate Postfix VRFY"
echo "[ ] Step 4 - write hardened /etc/exports"
echo "[ ] Step 5 - deactivate NFSv2/v3 (only v4)"
echo "[ ] Step 6 - remove EXPORTS-Alias and vulnix-rule from sudoers"


# --- 0. run as root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Please run script as root." >&2
  exit 1
fi

# --- 1. backups files ---
# (for rollback on fail)
BACKUP_DIR="/root/backup_vulnix_fix_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "[*] Step 1 - backups to $BACKUP_DIR"

for f in /etc/exports \
         /etc/sudoers \
         /etc/inetd.conf \
         /etc/postfix/main.cf \
         /etc/default/nfs-kernel-server; do
    if [ -f "$f" ]; then
        cp -a "$f" "$BACKUP_DIR/" # -a to keep rights, owner and timestamp
        echo "    saved: $f"
    else
        echo "    skipped (not existing): $f"
    fi
done


# --- 2. close recon-vector - finger ---
echo "[*] Step 2 - disable fingerd and r-services"
# disable finger & r-services in inetd.conf, then reload inetd
if [ -f /etc/inetd.conf ]; then
    # sed-substitude
    # /ADDRESS/s/SEARCH/REPLACE
    # /.../ Boundaries of the pattern
    # ^ = Start of line
    # [[:space:]] = followed by a space or a tab
    # s/^/#/ = put a # at the start of the line -> commented out
    sed -i -E '/^(shell|login|exec|finger)[[:space:]]/s/^/#/' /etc/inetd.conf
    service openbsd-inetd restart 2>/dev/null || service inetutils-inetd restart 2>/dev/null || true
fi

# --- 3. close recon-vectors - SMTP VRFY ---
echo "[*] Step 3 - deactivate Postfix VRFY"
if [ -f /etc/postfix/main.cf ]; then
    # remove line, set clean new line (idempotent)
    sed -i '/^disable_vrfy_command/d' /etc/postfix/main.cf
    echo "disable_vrfy_command = yes" >> /etc/postfix/main.cf
    service postfix reload 2>/dev/null || true
fi


# --- 4. harden NFS export ---
echo "[*] Step 4 - write hardened /etc/exports"
cat > /etc/exports <<'EOF'
# Hardened NFS-Export
# - only local subnet instead of wildcard *  -> blocks external clients (Foothold)
# - root_squash: root-Client becomes nobody -> prevents no_root_squash-PrivEsc
# - all_squash:  every UID becomes nobody   -> breaks UID-Spoofing (my Foothold)
# - no_subtree_check: Best-Practice-Default (stability)
/home/vulnix 10.10.10.0/24(rw,root_squash,all_squash,no_subtree_check)
EOF

exportfs -ra   # refresh export list
echo "    exports reloaded"

# --- 5. NFSv3/v2 switch off -> only NFSv4 (Downgrade-Protection against UID-Spoofing) ---
echo "[*] Step 5 - deactivate NFSv2/v3 (only v4)"
NFS_DEFAULT="/etc/default/nfs-kernel-server"
if [ -f "$NFS_DEFAULT" ]; then
    sed -i '/^RPCNFSDOPTS/d' "$NFS_DEFAULT"           # remove old line (idempotent)
    echo 'RPCNFSDOPTS="--no-nfs-version 2 --no-nfs-version 3"' >> "$NFS_DEFAULT"
    service nfs-kernel-server restart 2>/dev/null || true
    echo "    NFS server restarted (v4 only)"
fi

# --- 6. remove overprivileged sudo rule ---
echo "[*] Step 6 - remove EXPORTS-Alias and vulnix-rule from sudoers"
# Changes on sudoers only via a copy to avoid broken access though missconfiguration
TMP_SUDOERS="$(mktemp)"
cp -a /etc/sudoers "$TMP_SUDOERS"

sed -i '/^Cmnd_Alias EXPORTS/d' "$TMP_SUDOERS"
sed -i '/^vulnix[[:space:]]/d'  "$TMP_SUDOERS"

if visudo -c -f "$TMP_SUDOERS" >/dev/null 2>&1; then
    cp -a "$TMP_SUDOERS" /etc/sudoers
    echo "    sudo rule removed (syntax checked)"
else
    echo "    ERROR: invalid sudoers syntax - change discarted!" >&2
fi
rm -f "$TMP_SUDOERS"


echo "=== Done. Please Verify by run attack chain again. ==="