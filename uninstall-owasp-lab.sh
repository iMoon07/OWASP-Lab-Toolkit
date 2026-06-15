#!/bin/bash

# ==============================================================================
# OWASP LAB TOOLKIT - NUCLEAR UNINSTALLER
# Developed by iMoon (linkedin.com/in/imoon07) · infosec-world.id · Inspired by Taro Lay (linkedin.com/in/tarolay)
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
   exit 1
fi

# -----------------------------------------
# [ CONFIGURATION ]
# Memuat Config & UI / Load Settings
# -----------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/owasp-apps.conf" ]; then
    source "${SCRIPT_DIR}/owasp-apps.conf"
else
    echo -e "\033[1;31m[!] Error: Missing owasp-apps.conf.\033[0m"
    exit 1
fi

if [ -f /etc/owasp-lab/config.env ]; then
    source /etc/owasp-lab/config.env
fi

# -----------------------------------------
# [ UI / FRONTEND ]
# Tampilan Layar / Terminal Display
# -----------------------------------------
clear

echo -e "${REDBG}${YLW}                                                                        ${RST}"
echo -e "${REDBG}${YLW}                  OWASP LAB UNINSTALLER (NUCLEAR MODE)                  ${RST}"
echo -e "${REDBG}${YLW}                                                                        ${RST}"
echo ""

_print_ascii_art

_tp "${RED}┄┄ NUCLEAR UNINSTALL PHASE ┄┄┄┄┄┄┄┄┄${RST}"
_tp "${DIM}WARNING: This will DESTROY everything!${RST}"
_tp ""
_tp "${WHT}Data to be wiped / Data yang akan dihancurkan:${RST}"
_tp "${WHT}- MariaDB Databases & Users${RST}"
_tp "${WHT}- Apache, Nginx, PHP (All Versions & Binaries)${RST}"
_tp "${WHT}- Java (Temurin/OpenJDK), NodeJS & NPM${RST}"
_tp "${WHT}- Apache Tomcat & All Vulnerable Web Apps (bWAPP, WebGoat, dll)${RST}"
_tp "${WHT}- Config Files (/etc/owasp-lab, /etc/nginx, /etc/php, /etc/mysql)${RST}"
_tp "${WHT}- SystemD Services, Firewall Rules (UFW/IPTables NAT)${RST}"
_tp "${WHT}- Swapfile & Custom /etc/hosts records${RST}"
_tp ""

_prmpt "${RED}[?] Type 'DESTROY' to confirm: ${RST}"
read confirm
if [[ "$confirm" != "DESTROY" ]]; then
   echo -e "\n${GRN}[*] Uninstallation cancelled. Safe!${RST}"
   exit 1
fi

echo ""
echo -e "${RED}  [!] INITIATING NUCLEAR WIPE...${RST}"
sleep 1

# Setup Logging
tput civis
trap 'tput cnorm; echo ""; exit 1' EXIT INT TERM
LOG_FILE="${SCRIPT_DIR}/owasp-lab.log"
> "$LOG_FILE"

# ==========================================
# [ BACKEND EXECUTION ]
# Eksekusi Utama / Main Core Process
# ==========================================

_hdr "CLEAN PURGE & UNLINKING (NUCLEAR)"

_stop_services() {
    local SERVICES_TO_STOP=(
        "apache2" "nginx" "mariadb"
        "juiceshop" "webgoat" "webwolf" "tomcat"
    )
    
    for s in "${SERVICES_TO_STOP[@]}"; do
        systemctl stop "$s" 2>/dev/null || true
        systemctl disable "$s" 2>/dev/null || true
    done
    
    if [ -f /etc/owasp-lab-manifest.txt ]; then
        grep "\.service$" /etc/owasp-lab-manifest.txt | while read svc; do
            local svc_name=$(basename "$svc")
            systemctl stop "$svc_name" 2>/dev/null || true
            systemctl disable "$svc_name" 2>/dev/null || true
        done
    fi
}
_run "Stopping and Disabling Daemons" "_stop_services"

# ------------------------------------------------------------------------------
_hdr "MANIFEST FILE PURGE (DYNAMIC DELETION)"

_purge_manifest() {
    # 1. Purge items listed in manifest
    if [ -f /etc/owasp-lab-manifest.txt ]; then
        while IFS= read -r path; do
            if [ -n "$path" ] && [ "$path" != "/" ] && [ "$path" != "/etc" ] && [ "$path" != "/usr" ]; then
                rm -rf "$path"
            fi
        done < /etc/owasp-lab-manifest.txt
    fi
    
    # 2. Dynamic Purge from Apps Array
    for app in "${APPS_LIST[@]}"; do
        rm -rf "${APP_DIR[$app]}" 2>/dev/null || true
        rm -rf "${APP_DOCROOT[$app]}" 2>/dev/null || true
        rm -f "/etc/systemd/system/${app}.service" 2>/dev/null || true
    done
    
    # Completely destroy OWASP Lab configs
    rm -rf /etc/owasp-lab
    
    # 3. Hardcoded directories wipe
    local DIRS_TO_PURGE=(
        "/etc/apache2" "/etc/nginx" "/etc/php" "/etc/mysql" 
        "/var/www/html" "/var/www/hack" "/usr/local/share/src-analysis" "/opt/tomcat"
        "/opt/java" "/opt/nodejs" "/usr/local/mysql" "/usr/local/mariadb" 
        "/usr/local/apache2" "/usr/local/nginx"
    )
    for d in "${DIRS_TO_PURGE[@]}"; do rm -rf "$d" 2>/dev/null || true; done
    
    # 4. Hardcoded files wipe
    local FILES_TO_PURGE=(
        "/etc/systemd/system/apache2-custom.service"
        "/etc/systemd/system/nginx-custom.service"
        "/etc/systemd/system/mariadb-custom.service"
        "/etc/systemd/system/mysql-custom.service"
        "/etc/apt/keyrings/mariadb-keyring.gpg"
        "/etc/apt/keyrings/adoptium.asc"
        "/etc/apt/sources.list.d/mariadb.list"
        "/etc/apt/sources.list.d/adoptium.list"
        "/etc/owasp-lab-manifest.txt"
    )
    for f in "${FILES_TO_PURGE[@]}"; do rm -f "$f" 2>/dev/null || true; done
    
    # 5. Purge Packages
    export DEBIAN_FRONTEND=noninteractive
    local PACKAGES_TO_PURGE=(
        "apache2*" "nginx*" "mariadb-*" "php*" 
        "nodejs*" "temurin-*" "openjdk-*" "default-jre*" "default-jdk*"
    )
    for pkg in "${PACKAGES_TO_PURGE[@]}"; do
        apt-get purge -y "$pkg" || true
    done
    apt-get autoremove -y || true
    
    # 6. Remove Swap
    if grep '/swapfile' /etc/fstab; then
        swapoff /swapfile 2>/dev/null || true
        rm -f /swapfile
        sed -i '/\/swapfile/d' /etc/fstab
    fi
    
    # 7. Remove Hosts
    sed -i '/owasp\.hacking/d' /etc/hosts
    
    systemctl daemon-reload
}
_run "Reading Manifest & Destroying Environment" "_purge_manifest"

# ------------------------------------------------------------------------------
_hdr "FIREWALL & NAT CLEANUP"

_clean_firewall() {
    # Flush NAT
    iptables -t nat -F PREROUTING 2>/dev/null || true
    
    # Build unique port list
    local PORTS_LIST=(80 443)
    for app in "${APPS_LIST[@]}"; do PORTS_LIST+=("${APP_PORT[$app]}"); done
    PORTS_LIST=($(printf "%s\n" "${PORTS_LIST[@]}" | sort -u))
    
    if command -v ufw >/dev/null; then
        for p in "${PORTS_LIST[@]}"; do ufw delete allow $p/tcp >/dev/null 2>&1 || true; done
    elif command -v firewall-cmd >/dev/null; then
        for p in "${PORTS_LIST[@]}"; do firewall-cmd --remove-port=$p/tcp --permanent >/dev/null 2>&1 || true; done
        firewall-cmd --reload >/dev/null 2>&1 || true
    fi
}
_run "Cleaning Firewalls & IPTables NAT" "_clean_firewall"

echo ""
echo -e "${GRN}  [+] Uninstallation Completed. System is clean.${RST}"

tput cnorm
exit 0
