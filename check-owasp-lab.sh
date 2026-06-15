#!/bin/bash

# ==============================================================================
# OWASP LAB TOOLKIT - HEALTH CHECKER
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
# [ HELPERS ]
# Fungsi Cek Status / Status Functions
# -----------------------------------------
check_file() {
    local file_path="$1"
    local description="$2"
    if [ -f "$file_path" ]; then
        _tp "${GRN}[ OK ]${RST} $description"
    else
        _tp "${RED}[FAIL]${RST} $description"
    fi
}

check_dir() {
    local dir_path="$1"
    local description="$2"
    if [ -d "$dir_path" ]; then
        _tp "${GRN}[ OK ]${RST} $description"
    else
        _tp "${RED}[FAIL]${RST} $description"
    fi
}

check_service() {
    local service_name="$1"
    local display_name="$2"
    
    if systemctl is-active --quiet "$service_name" 2>/dev/null; then
        _tp "  $(printf '%-10s' "$display_name") : ${GRN}[ RUNNING ]${RST}"
    else
        _tp "  $(printf '%-10s' "$display_name") : ${RED}[ STOPPED ]${RST}"
    fi
}

check_http_endpoint() {
    local app_name="$1"
    local port="$2"
    local engine="$3"
    local uri="$4"
    
    local route="Nginx -> ${engine^} ($port)"
    local url="https://${app_name}.owasp.hacking${uri}"
    
    local col="$CYN"
    if [ "$engine" == "node" ]; then col="$MAG"; fi
    if [ "$engine" == "java" ]; then col="$BLU"; fi
    
    local display_name="${APP_DISPLAY_NAME[$app_name]:-${app_name^}}"
    
    local code=$(curl -s -k -o /dev/null -w "%{http_code}" -H "Host: ${app_name}.owasp.hacking" "https://127.0.0.1:443" --connect-timeout 2)
    local http_stat="${RED}[DOWN]${RST}"
    if [[ "$code" =~ ^(200|301|302|401|403|404)$ ]]; then
        http_stat="${GRN}[ UP ]${RST}"
    fi
    
    printf "  ${WHT}%-10s${RST} | ${col}%-25s${RST} | %-38s | %b\n" "$display_name" "$route" "$url" "$http_stat"
}

# ==========================================
# [ LIVE LOOP ]
# CLI Utama Interaktif / Main UI Loop
# ==========================================

while true; do
    clear
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    echo -e "${REDBG}${YLW}                  OWASP LAB: HEALTH & TELEMETRY CHECK                   ${RST}"
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    _print_ascii_art

    _hdr "INTERACTIVE DASHBOARD"
    _tp "  ${WHT}[1]${RST} Check Application Endpoints (UP / DOWN)"
    _tp "  ${WHT}[2]${RST} Show Web Credentials & Locations"
    _tp "  ${WHT}[3]${RST} Display Hosts File Configuration"
    _tp "  ${WHT}[4]${RST} Check System Daemons Status"
    _tp "  ${WHT}[5]${RST} Diagnostics (Configs & Vulnerable Dirs)"
    _tp "  ${WHT}[6]${RST} Engine & Stack Versions"
    _tp "  ${WHT}[0]${RST} Exit Dashboard"
    echo ""
    _prmpt "${CYN}Select an option [0-6] > ${RST}"
    read opt

    clear
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    echo -e "${REDBG}${YLW}                  OWASP LAB: HEALTH & TELEMETRY CHECK                   ${RST}"
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    _print_ascii_art

    case "$opt" in
        1)
            _hdr "APPLICATION ENDPOINTS & HEALTH"
            echo -e "  ${WHT}APP NAME   | NGINX (443) -> INTERNAL   | ENDPOINT URL                           | HTTP${RST}"
            echo -e "  -----------|---------------------------|----------------------------------------|------"
            for app in "${APPS_LIST[@]}"; do
                check_http_endpoint "$app" "${APP_PORT[$app]}" "${APP_ENGINE[$app]}" "${APP_URI[$app]}"
            done
            ;;
        2)
            _hdr "WEB CREDENTIALS & APP LOCATIONS"
            for app in "${APPS_LIST[@]}"; do
                doc_root="${APP_DOCROOT[$app]}"
                user_cred="${APP_CREDS_USER[$app]}"
                pass_cred="${APP_CREDS_PASS[$app]}"
                display_name="${APP_DISPLAY_NAME[$app]:-${app^}}"
                
                path_display="/var/www/hack/${doc_root}"
                if [[ "$doc_root" == /opt* ]]; then path_display="$doc_root"; fi
                
                if [ "$user_cred" == "-" ]; then
                    printf "  ${WHT}[+] %-10s : ${DIM}Register to use   (%s)${RST}\n" "$display_name" "$path_display"
                else
                    printf "  ${WHT}[+] %-10s : ${YLW}%s ${WHT}/ ${YLW}%-10s ${DIM}(%s)${RST}\n" "$display_name" "$user_cred" "$pass_cred" "$path_display"
                fi
            done
            ;;
        3)
            SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
            if [ -z "$SERVER_IP" ]; then SERVER_IP="192.168.X.X"; fi

            _hdr "HOSTS CONFIGURATION (REQUIRED)"
            echo -e "  ${WHT}To access the lab, copy the block below and append it to your OS 'hosts' file:${RST}"
            echo -e "  ${DIM}(Windows: C:/Windows/System32/drivers/etc/hosts | Linux/Mac: /etc/hosts)${RST}\n"
            echo -e "  ${GRN}${SERVER_IP}${RST}  ${YLW}${APPS_LIST[*]/%/.owasp.hacking}${RST}"
            ;;
        4)
            _hdr "SYSTEM DAEMONS STATUS"
            check_service "apache2.service"   "Apache2"
            check_service "nginx.service"     "Nginx"
            check_service "juiceshop.service" "Juice Shop"
            check_service "webgoat.service"   "WebGoat"
            check_service "webwolf.service"   "WebWolf"
            check_service "tomcat.service"    "Tomcat"
            ;;
        5)
            _hdr "DIAGNOSTIC PHASE (CONF & LOGS)"
            check_file "/etc/apache2/apache2.conf"       "Apache Conf : /etc/apache2/apache2.conf"
            check_file "/etc/nginx/nginx.conf"           "Nginx Conf  : /etc/nginx/nginx.conf"
            check_dir  "/etc/mysql/"                     "MariaDB Dir : /etc/mysql/"
            check_file "/etc/php/8.3/apache2/php.ini"    "PHP Config  : /etc/php/8.3/apache2/php.ini"
            
            _hdr "SERVER LOG FILES"
            check_file "/var/log/apache2/error.log"      "Apache Error: /var/log/apache2/error.log"
            check_file "/var/log/apache2/access.log"     "Apache Accss: /var/log/apache2/access.log"
            check_file "/var/log/nginx/error.log"        "Nginx Error : /var/log/nginx/error.log"
            check_file "/var/log/nginx/access.log"       "Nginx Accss : /var/log/nginx/access.log"
            
            _hdr "VULNERABLE DIRECTORIES"
            check_dir  "/var/www/hack"                   "PHP Vulns   : /var/www/hack"
            check_dir  "/opt/juiceshop"                  "JS Vulns    : /opt/juiceshop"
            check_dir  "/opt/webgoat"                    "Java Vulns  : /opt/webgoat"
            ;;
        6)
            _hdr "INSTALLED ENGINE VERSIONS"
            [ -f /usr/sbin/apache2 ] && echo -e "  ${WHT}[+] Apache : $(/usr/sbin/apache2 -v 2>&1 | head -n 1 | awk '{print $3}')${RST}"
            [ -f /usr/sbin/nginx ]   && echo -e "  ${WHT}[+] Nginx  : $(/usr/sbin/nginx -v 2>&1 | awk -F'/' '{print $2}')${RST}"
            [ -f /usr/bin/php ]      && echo -e "  ${WHT}[+] PHP    : $(/usr/bin/php -v 2>&1 | head -n 1 | awk '{print $2}')${RST}"
            [ -f /usr/bin/mysql ]    && echo -e "  ${WHT}[+] MariaDB: $(/usr/bin/mysql -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-MariaDB' || echo 'Unknown')${RST}"
            [ -f /usr/bin/node ]     && echo -e "  ${WHT}[+] Node.js: $(/usr/bin/node -v 2>&1)${RST}"
            [ -f /usr/bin/java ]     && echo -e "  ${WHT}[+] Java   : $(/usr/bin/java -version 2>&1 | awk -F '"' '/version/ {print $2}')${RST}"
            ;;
        0)
            echo -e "\n  ${GRN}[+] Exiting Dashboard. Have a good day!${RST}\n"
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}[!] Invalid option selected.${RST}"
            ;;
    esac

    echo ""
    _prmpt "${DIM}Press [ENTER] to return to the Dashboard...${RST}"
    read
done
