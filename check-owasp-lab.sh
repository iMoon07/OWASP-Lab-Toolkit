#!/bin/bash

# ==============================================================================
# OWASP LAB TOOLKIT v1.1 - HEALTH CHECKER
# Developed by iMoon (linkedin.com/in/imoon07) · infosec-world.id · Inspired by Taro Lay (linkedin.com/in/tarolay)
# ==============================================================================


if [[ $EUID -ne 0 ]]; then
   exec sudo "$0" "$@"
   exit 1
fi

# -----------------------------------------
# [ CONFIGURATION ]
# Load Configurations & UI Settings
# -----------------------------------------
if [ -f /etc/owasp-lab/config.env ]; then
    source /etc/owasp-lab/config.env
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/owasp-apps.conf" ]; then
    source "${SCRIPT_DIR}/owasp-apps.conf"
else
    echo -e "\033[1;31m[!] Error: Missing owasp-apps.conf.\033[0m"
    exit 1
fi

# -----------------------------------------
# [ HELPERS ]
# Status Verification Functions
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
    local url="https://${app_name}.${DOMAIN:-owasp.hacking}${uri}"
    
    local col="$CYN"
    if [ "$engine" == "node" ]; then col="$MAG"; fi
    if [ "$engine" == "java" ]; then col="$BLU"; fi
    
    local display_name="${APP_DISPLAY_NAME[$app_name]:-${app_name^}}"
    
    local code=$(curl -s -k -o /dev/null -w "%{http_code}" -H "Host: ${app_name}.${DOMAIN:-owasp.hacking}" "https://127.0.0.1:443" --connect-timeout 2)
    local http_stat="${DIM}[ DOWN ]${RST}"
    if [[ "$code" =~ ^(200|301|302|401|403|404)$ ]]; then
        http_stat="${GRN}[ NORMAL ]${RST}"
    elif [[ "$code" =~ ^(500|502|503|504)$ ]]; then
        http_stat="${RED}[CRITICAL]${RST}"
    fi
    
    printf "  ${WHT}%-10s${RST} | ${col}%-25s${RST} | %-38s | %b\n" "$display_name" "$route" "$url" "$http_stat"
}

# ==========================================
# [ LIVE LOOP ]
# Main Interactive CLI Loop
# ==========================================

run_option() {
    local opt="$1"
    case "$opt" in
        1)
            _hdr "APPLICATION ENDPOINTS & HEALTH"
            echo -e "  ${WHT}APP NAME   | NGINX (443) -> INTERNAL   | ENDPOINT URL                           | HTTP${RST}"
            echo -e "  -----------|---------------------------|----------------------------------------|---------"
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
            echo -e "  ${GRN}${SERVER_IP}${RST}  ${YLW}${APPS_LIST[*]/%/.${DOMAIN:-owasp.hacking}}${RST}"
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
            _hdr "INSTALLED ENGINE & TECH STACK VERSIONS"
            echo -e "  ${WHT}ENGINE / STACK     | VERSION INFORMATION            | BINARY PATH${RST}"
            echo -e "  -------------------|--------------------------------|------------------------"
            
            local v_apache="Not Installed"
            local v_nginx="Not Installed"
            local v_php="Not Installed"
            local v_mysql="Not Installed"
            local v_node="Not Installed"
            local v_java="Not Installed"
            local v_npm="Not Installed"
            
            [ -f /usr/sbin/apache2 ] && v_apache=$(/usr/sbin/apache2 -v 2>&1 | head -n 1 | awk '{print $3}')
            [ -f /usr/sbin/nginx ]   && v_nginx=$(/usr/sbin/nginx -v 2>&1 | awk -F'/' '{print $2}')
            [ -f /usr/bin/php ]      && v_php=$(/usr/bin/php -v 2>&1 | head -n 1 | awk '{print $2}')
            [ -f /usr/bin/mysql ]    && v_mysql=$(/usr/bin/mysql -V 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-MariaDB' || echo 'Unknown')
            [ -f /usr/bin/node ]     && v_node=$(/usr/bin/node -v 2>&1)
            [ -f /usr/bin/npm ]      && v_npm=$(/usr/bin/npm -v 2>&1)
            [ -f /usr/bin/java ]     && v_java=$(/usr/bin/java -version 2>&1 | awk -F '"' '/version/ {print $2}')

            printf "  ${CYN}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "Apache (Backend)" "$v_apache" "/usr/sbin/apache2"
            printf "  ${CYN}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "Nginx (Proxy)" "$v_nginx" "/usr/sbin/nginx"
            printf "  ${CYN}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "PHP Engine" "$v_php" "/usr/bin/php"
            printf "  ${CYN}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "MariaDB Server" "$v_mysql" "/usr/bin/mysql"
            printf "  ${MAG}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "Node.js" "$v_node" "/usr/bin/node"
            printf "  ${MAG}%-18s${RST} | ${YLW}%-30s${RST} | ${DIM}%-20s${RST}\n" "NPM Package Mgr" "$v_npm" "/usr/bin/npm"
            ;;

        0)
            echo -e "\n  ${GRN}[+] Exiting Menu. Have a good day!${RST}\n"
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}[!] Invalid option selected.${RST}"
            ;;
    esac
}

# Web Mode Handler (Non-Interactive)
if [ "$1" == "--web" ]; then
    run_option "$2"
    exit 0
fi



while true; do
    clear
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    echo -e "${REDBG}${YLW}                  OWASP LAB: HEALTH & TELEMETRY CHECK                   ${RST}"
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    _print_ascii_art

    _hdr "INTERACTIVE MENU"
    _tp "  ${WHT}[1]${RST} Check Application Endpoints (UP / DOWN)"
    _tp "  ${WHT}[2]${RST} Show Web Credentials & Locations"
    _tp "  ${WHT}[3]${RST} Display Hosts File Configuration"
    _tp "  ${WHT}[4]${RST} Check System Daemons Status"
    _tp "  ${WHT}[5]${RST} Diagnostics (Configs & Vulnerable Dirs)"
    _tp "  ${WHT}[6]${RST} Engine & Stack Versions"
    _tp "  ${WHT}[0]${RST} Exit Menu"
    echo ""
    _prmpt "${CYN}Select an option [0-6] > ${RST}"
    read opt

    clear
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    echo -e "${REDBG}${YLW}                  OWASP LAB: HEALTH & TELEMETRY CHECK                   ${RST}"
    echo -e "${REDBG}${YLW}                                                                        ${RST}"
    _print_ascii_art

    if [ "$opt" == "1" ]; then
        while true; do
            clear
            run_option "1"
            echo ""
            _prmpt "${DIM}[R] Refresh Status   [ENTER] Back to Menu${RST}: "
            read -r refresh_cmd
            if [[ "$refresh_cmd" != "r" && "$refresh_cmd" != "R" ]]; then
                break
            fi
        done
        continue
    else
        run_option "$opt"
    fi

    echo ""
    _prmpt "${DIM}Press [ENTER] to return to the Menu...${RST}"
    read
done
