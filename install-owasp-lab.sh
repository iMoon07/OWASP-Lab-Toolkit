#!/bin/bash
# ==============================================================================
# OWASP LAB TOOLKIT - INSTALLER
# Developed by iMoon (linkedin.com/in/imoon07) · infosec-world.id · Inspired by Taro Lay (linkedin.com/in/tarolay)
# ==============================================================================

# Disable Git terminal prompt
export GIT_TERMINAL_PROMPT=0

# Keep sudo token alive
while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &

# Load Central Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/owasp-apps.conf" ]; then
    source "${SCRIPT_DIR}/owasp-apps.conf"
else
    echo -e "\033[1;31m[!] Error: Missing owasp-apps.conf.\033[0m"
    exit 1
fi

# ==========================================
# [ UI / FRONTEND ]
# Tampilan Layar Utama / Terminal Display
# ==========================================
# Clear screen and show banner
clear
echo -e "${REDBG}${YLW}                                                                        ${RST}"
echo -e "${REDBG}${YLW}                      OWASP LAB TOOLKIT INSTALLER                       ${RST}"
echo -e "${REDBG}${YLW}                                                                        ${RST}"
_print_ascii_art

_tp "${CYN}┄┄ CONFIGURATION PHASE ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RST}"

CONFIG_FILE="/etc/owasp-lab/config.env"
DEFAULT_DOMAIN="owasp.hacking"
DEFAULT_ORG="OWASP Lab Toolkit"
DEFAULT_DBUSER="owasp_user"
DEFAULT_DBPASS="Owasp#Lab123"

# Prompt Logic
USE_EXISTING="N"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    _prmpt "${GRN}[*] Found config ($DOMAIN). Use it? (Y/n): ${RST}"
    read use_config
    [[ "$use_config" != "N" && "$use_config" != "n" ]] && USE_EXISTING="Y" || echo ""
fi

if [ "$USE_EXISTING" == "N" ]; then
    mkdir -p /etc/owasp-lab
    > "$CONFIG_FILE"
    _tp "${DIM}Press [ENTER] to use Default values.${RST}"
    _tp ""
    ask_config DOMAIN   "1. Domain"    "$DEFAULT_DOMAIN"
    ask_config SSL_ORG  "2. SSL Org"   "$DEFAULT_ORG"
    ask_config DB_USER  "3. DB User"   "$DEFAULT_DBUSER"
    ask_config DB_PASS  "4. DB Pass"   "$DEFAULT_DBPASS"   "1"
fi

_tp ""
_tp "${GRN}┄┄ INSTALLATION SUMMARY ┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RST}"
_tp "${WHT}[+] Domain : ${YLW}$DOMAIN${RST}"
_tp "${WHT}[+] SSL    : ${YLW}$SSL_ORG${RST}"
_tp "${WHT}[+] DB User: ${YLW}$DB_USER${RST}"
_tp "${WHT}[+] DB Pass: ${YLW}$DB_PASS${RST}"
_tp ""

if [ "$USE_EXISTING" == "N" ]; then
    _prmpt "${CYN}[?] Proceed? (Y/n): ${RST}"
    read confirm
    if [[ "$confirm" != "Y" && "$confirm" != "y" && "$confirm" != "" ]]; then
       echo ""
       echo -e "${RED}[x] Installation aborted.${RST}"
       exit 1
    fi
fi

echo -e "\n${GRN}  [*] Configuration saved. Initializing backend engine...${RST}"
sleep 1

# Start Backend Execution
tput civis
trap 'tput cnorm; echo ""; exit 1' EXIT INT TERM
LOG_FILE="${SCRIPT_DIR}/owasp-lab.log"
> "$LOG_FILE"

# ==========================================
# [ BACKEND EXECUTION ]
# Eksekusi Utama / Main Core Process
# ==========================================

# ------------------------------------------------------------------------------
_hdr "PREPARING SYSTEM"

_cleanup_stalled() {
    local PROCS_TO_KILL=("git" "wget" "curl" "unzip" "tar")
    for p in "${PROCS_TO_KILL[@]}"; do killall -9 "$p" 2>/dev/null || true; done

    local FILES_TO_RM=(
        "/var/lib/apt/lists/lock"
        "/var/cache/apt/archives/lock"
    )
    for f in "${FILES_TO_RM[@]}"; do rm -f "$f" 2>/dev/null || true; done
    rm -f /var/lib/dpkg/lock* 2>/dev/null || true
    dpkg --configure -a 2>/dev/null || true
}
_run "Cleaning Stalled Apt Processes" "_cleanup_stalled"

_prep_env() {
    local DIRS_TO_CREATE=(
        "/etc/owasp-lab"
        "/usr/local/src/owasp-tarballs"
    )
    for d in "${DIRS_TO_CREATE[@]}"; do
        mkdir -p "$d"
        track_path "$d"
    done
    
    # 4GB Swap
    if [ ! -f /swapfile ]; then
        fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
}
_run "Environment & 4GB Swap Prep" "_prep_env"

_install_deps() {
    export DEBIAN_FRONTEND=noninteractive
    
    local DEPS_LIST=(
        "wget" "curl" "git" "ufw" "python3" "python3-pip"
        "software-properties-common" "gnupg2" "apt-transport-https" 
        "ca-certificates" "dpkg-dev"
    )
    
    apt-get update -y
    apt-get install -y "${DEPS_LIST[@]}"
}
_run "Installing Core Dependencies" "_install_deps"

# ------------------------------------------------------------------------------
_hdr "REPOSITORIES & PACKAGES"

_inject_repos() {
    export DEBIAN_FRONTEND=noninteractive
    
    local PPAS_LIST=(
        "ppa:ondrej/php"
        "ppa:ondrej/apache2"
    )
    for ppa in "${PPAS_LIST[@]}"; do
        add-apt-repository -y "$ppa" || true
    done
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - || true
    
    # Adoptium Java & MariaDB
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public > /etc/apt/keyrings/adoptium.asc
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" > /etc/apt/sources.list.d/adoptium.list
    
    curl -fsSL https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor --batch --yes -o /etc/apt/keyrings/mariadb-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/mariadb-keyring.gpg] https://mirrors.xtom.com/mariadb/repo/11.4/ubuntu $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" > /etc/apt/sources.list.d/mariadb.list

    sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list
    sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources || true
    apt-get update -y
}
_run "Injecting PHP, Node, Java, MariaDB PPAs" "_inject_repos"

_install_engines() {
    export DEBIAN_FRONTEND=noninteractive
    
    local ENGINES_LIST=(
        "apache2" "nginx" "mariadb-server" 
        "php8.3" "php8.3-mysql" "php8.3-curl" "php8.3-mbstring" "php8.3-xml" "php8.3-gd" "php8.3-zip"
        "nodejs" "temurin-21-jdk"
    )
    apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" "${ENGINES_LIST[@]}"
    
    local tomcat_dir="${APP_DIR[tomcat]}"
    if [ ! -d "$tomcat_dir" ]; then
        mkdir -p "$tomcat_dir"
        wget "${APP_URL[tomcat]}" -O /tmp/tomcat.tar.gz
        tar -xf /tmp/tomcat.tar.gz -C "$tomcat_dir" --strip-components=1
        rm -f /tmp/tomcat.tar.gz
        
        sed -i 's/port="8080"/port="8082"/g' "$tomcat_dir/conf/server.xml"
    fi
        
    # Format XML Config clearly (runs every time to ensure creds are updated)
    if [ -d "$tomcat_dir/conf" ]; then
        cat <<-EOF > "$tomcat_dir/conf/tomcat-users.xml"
<?xml version='1.0' encoding='utf-8'?>
<tomcat-users>
    <role rolename="manager-gui"/>
    <role rolename="admin-gui"/>
    <user username="${DB_USER}" password="${DB_PASS}" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF
    fi
    
    local SERVICES_TO_ENABLE=("apache2" "nginx" "mariadb")
    for srv in "${SERVICES_TO_ENABLE[@]}"; do systemctl enable "$srv" || true; done
    
    a2dissite 000-default default-ssl || true
    rm -f /etc/nginx/sites-enabled/default
}
_run "Installing Web & Database Engines" "_install_engines"

_config_php() {
    local php_ini="/etc/php/8.3/apache2/php.ini"
    local PHP_TWEAKS=(
        "file_uploads = Off|file_uploads = On"
        "allow_url_fopen = Off|allow_url_fopen = On"
        "allow_url_include = Off|allow_url_include = On"
    )
    for t in "${PHP_TWEAKS[@]}"; do 
        local from="${t%%|*}"
        local to="${t##*|}"
        sed -i "s/${from}/${to}/" "$php_ini"
    done
    
    echo "<?php mysqli_report(MYSQLI_REPORT_OFF); ?>" > /etc/php/8.3/apache2/disable_strict_mysqli.php
    echo "auto_prepend_file = /etc/php/8.3/apache2/disable_strict_mysqli.php" >> "$php_ini"
}
_run "Applying Vulnerable PHP Configs" "_config_php"

# ------------------------------------------------------------------------------
_hdr "APPLICATION CLONING & SETUP"

_clone_apps() {
    local HACK_DIR="/var/www/hack"
    mkdir -p "$HACK_DIR"
    track_path "$HACK_DIR"
    cd "$HACK_DIR"
    
    for app in "${APPS_LIST[@]}"; do
        local url="${APP_URL[$app]}" 
        local clone_dir="${APP_DIR[$app]}"
        
        if [[ "$url" == *.git ]]; then
            if [ ! -d "$clone_dir" ]; then
                git clone "$url" "$clone_dir"
            fi
            
            # Post clone fixes
            if [ "$app" == "dvwa" ]; then
                if [ -f "DVWA/config/config.inc.php.dist" ]; then
                    cp DVWA/config/config.inc.php.dist DVWA/config/config.inc.php
                fi
            fi
            
            if [ "$app" == "xvwa" ]; then
                if [ -d "xvwa" ] && [ ! -L "xvwa/xvwa" ]; then
                    ln -s . xvwa/xvwa
                fi
            fi
        fi
    done
    
    local js_dir="${APP_DIR[juiceshop]}" 
    local wg_dir="${APP_DIR[webgoat]}"
    
    mkdir -p "$js_dir" "$wg_dir"
    track_path "$js_dir"
    track_path "$wg_dir"
    
    cd "$js_dir"
    if [ ! -f "package.json" ]; then
        wget -qO- "${APP_URL[juiceshop]}" | tar -xz --strip-components=1 || true
    fi
    
    cd "$wg_dir"
    if [ ! -f "webgoat.jar" ]; then wget -qO webgoat.jar "${APP_URL[webgoat]}" || true; fi
    if [ ! -f "webwolf.jar" ]; then wget -qO webwolf.jar "${APP_URL[webwolf]}" || true; fi
    if [ ! -d "WebGoat-Source" ]; then git clone --branch v8.2.2 https://github.com/WebGoat/WebGoat.git WebGoat-Source || true; fi
    
    chown -R www-data:www-data "$HACK_DIR" 2>/dev/null || chown -R apache:apache "$HACK_DIR" 2>/dev/null || true
    chmod -R 755 "$HACK_DIR" || true
}
_run "Downloading All Vulnerable Applications" "_clone_apps"

_setup_db() {
    # Base setup
    mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
    mariadb -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';" || true
    local DBS_TO_CREATE=("dvwa" "xvwa" "mutillidae")
    for db in "${DBS_TO_CREATE[@]}"; do mariadb -e "CREATE DATABASE IF NOT EXISTS $db;"; done
    mariadb -e "GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION; FLUSH PRIVILEGES;"
    inject_db_creds "${DB_USER}" "${DB_PASS}"
    
    systemctl restart apache2 nginx mariadb
    
    # Wait for Apache and MariaDB to be ready
    for i in {1..15}; do
        if curl -s "http://127.0.0.1:8081/" >/dev/null && mariadb -e "SELECT 1;" >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    sleep 2
    
    # 1. DVWA (No direct MySQL setup needed, handled by HTTP)
    
    # 2. XVWA
    local XVWA_TABLES=("comments" "caffaine" "users")
    for tb in "${XVWA_TABLES[@]}"; do mariadb -e "CREATE TABLE IF NOT EXISTS xvwa.${tb} (id INT);" || true; done
    
    # 3. bWAPP & Mutillidae
    mariadb -e "DROP DATABASE IF EXISTS bWAPP;" || true
    
    # 4. VWA
    mariadb -e "DROP DATABASE IF EXISTS \`1ccb8097d0e9ce9f154608be60224c7c\`;" || true
}
_run "Initializing MySQL & App Databases" "_setup_db"

# ------------------------------------------------------------------------------
_hdr "NETWORKING & VIRTUAL HOSTS"

_setup_networking() {
    sed -i "/${DOMAIN}/d" /etc/hosts
    local host_str="127.0.0.1"
    for app in "${APPS_LIST[@]}"; do host_str="$host_str ${app}.${DOMAIN}"; done
    echo "$host_str" >> /etc/hosts

    local SSL_DIR="/etc/owasp-lab/ssl"
    mkdir -p "$SSL_DIR"
    track_path "$SSL_DIR"
    
    if [ ! -f "$SSL_DIR/owasp.key" ]; then
        openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
            -keyout "$SSL_DIR/owasp.key" \
            -out "$SSL_DIR/owasp.crt" \
            -subj "/C=US/ST=State/L=City/O=${SSL_ORG}/CN=*.${DOMAIN}"
    fi
}
_run "Setting up Hosts & Wildcard SSL" "_setup_networking"

_create_vhosts() {
    a2enmod rewrite proxy proxy_http || true
    a2dismod ssl || true
    sed -i 's/.*Listen 443/#Listen 443/g; s/.*Listen 80.*/Listen 127.0.0.1:8081/g' /etc/apache2/ports.conf || true
    
    for app in "${APPS_LIST[@]}"; do
        local engine="${APP_ENGINE[$app]}" 
        local doc_root="${APP_DOCROOT[$app]}"
        
        if [ "$engine" == "apache" ]; then
            cat <<-EOF > "/etc/apache2/sites-available/${app}.conf"
<VirtualHost 127.0.0.1:8081>
    ServerName ${app}.${DOMAIN}
    DocumentRoot "/var/www/hack/$doc_root"
    <Directory "/var/www/hack/$doc_root">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
            a2ensite "${app}.conf" || true
        fi
    done

    mkdir -p /etc/nginx/conf.d
    for app in "${APPS_LIST[@]}"; do
        local port="${APP_PORT[$app]}"
        cat <<-EOF > "/etc/nginx/conf.d/${app}.conf"
server {
    listen 80;
    server_name ${app}.${DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${app}.${DOMAIN};
    ssl_certificate /etc/owasp-lab/ssl/owasp.crt;
    ssl_certificate_key /etc/owasp-lab/ssl/owasp.key;

    location / {
        proxy_pass http://127.0.0.1:$port;
        proxy_set_header Host \$host;
    }
}
EOF
    done
}
_run "Creating Apache & Nginx Virtual Hosts" "_create_vhosts"

# ------------------------------------------------------------------------------
_hdr "SYSTEMD & DAEMONIZATION"

_create_svc() {
    local name=$1 desc=$2 type=$3 start=$4 stop=$5 pid=$6 user=$7 dir=$8 env=$9
    local after="network.target"
    if [ "$name" == "webwolf" ]; then after="webgoat.service"; fi
    
    local svc_file="/etc/systemd/system/${name}.service"
    
    echo "[Unit]" > "$svc_file"
    echo "Description=$desc" >> "$svc_file"
    echo "After=$after" >> "$svc_file"
    
    echo "[Service]" >> "$svc_file"
    if [ "$name" == "webwolf" ]; then echo "ExecStartPre=/bin/sleep 20" >> "$svc_file"; fi
    echo "Type=$type" >> "$svc_file"
    
    if [ -n "$user" ]; then echo "User=$user" >> "$svc_file"; fi
    if [ -n "$dir" ]; then echo "WorkingDirectory=$dir" >> "$svc_file"; fi
    if [ -n "$env" ]; then echo "Environment=$env" >> "$svc_file"; fi
    
    echo "ExecStart=$start" >> "$svc_file"
    if [ -n "$stop" ]; then echo "ExecStop=$stop" >> "$svc_file"; fi
    if [ -n "$pid" ]; then echo "PIDFile=$pid" >> "$svc_file"; fi
    
    echo "[Install]" >> "$svc_file"
    echo "WantedBy=multi-user.target" >> "$svc_file"
    
    track_path "$svc_file"
}

_create_services() {
    _create_svc "juiceshop" "Juice Shop" "simple" "/usr/bin/npm start" "" "" "root" "/opt/juiceshop" "PORT=3000"
    _create_svc "webgoat" "WebGoat" "simple" "/usr/bin/java -jar webgoat.jar --server.port=8080 --server.address=127.0.0.1" "" "" "root" "/opt/webgoat" ""
    _create_svc "webwolf" "WebWolf" "simple" "/usr/bin/java -jar webwolf.jar --server.port=9090 --server.address=127.0.0.1" "" "" "root" "/opt/webgoat" ""
    _create_svc "tomcat" "Apache Tomcat" "forking" "/opt/tomcat/bin/startup.sh" "/opt/tomcat/bin/shutdown.sh" "" "root" "/opt/tomcat" ""

    systemctl daemon-reload
    local SERVICES_LIST=("apache2" "nginx" "mariadb" "juiceshop" "webgoat" "webwolf" "tomcat")
    
    for s in "${SERVICES_LIST[@]}"; do
        systemctl enable "$s" || true
        systemctl restart "$s" || true
    done
}
_run "Start ALL Systemd Services" "_create_services"

_init_app_databases() {
    # 1. DVWA
    local DVWA_TOKEN=$(curl -s -c /tmp/cookies.txt -H "Host: dvwa.${DOMAIN}" "http://127.0.0.1:8081/setup.php" | grep "user_token" | awk -F"value='" '{print $2}' | awk -F"'" '{print $1}')
    curl -s -X POST -b /tmp/cookies.txt -d "create_db=Create+%2F+Reset+Database&user_token=${DVWA_TOKEN}" -H "Host: dvwa.${DOMAIN}" "http://127.0.0.1:8081/setup.php" >/dev/null 2>&1 || true
    
    # 2. XVWA
    curl -s -H "Host: xvwa.${DOMAIN}" "http://127.0.0.1:8081/setup/?action=do" >/dev/null 2>&1 || true
    
    # 3. bWAPP & Mutillidae
    curl -s -H "Host: bwapp.${DOMAIN}" "http://127.0.0.1:8081/install.php?install=yes" >/dev/null 2>&1 || true
    curl -s -H "Host: mutillidae.${DOMAIN}" "http://127.0.0.1:8081/set-up-database.php" >/dev/null 2>&1 || true
    
    # 4. VWA
    curl -s -X POST -d "submit=Enter" -H "Host: vwa.${DOMAIN}" "http://127.0.0.1:8081/index.php" >/dev/null 2>&1 || true
}
_run "Configuring Application Databases via HTTP" "_init_app_databases"

_firewall_setup() {
    local PORTS_LIST=(80 443)
    for app in "${APPS_LIST[@]}"; do PORTS_LIST+=("${APP_PORT[$app]}"); done
    
    # Sort and remove duplicates
    PORTS_LIST=($(printf "%s\n" "${PORTS_LIST[@]}" | sort -u))

    if command -v ufw >/dev/null; then
        for p in "${PORTS_LIST[@]}"; do ufw allow $p/tcp >/dev/null 2>&1; done
    elif command -v firewall-cmd >/dev/null; then
        for p in "${PORTS_LIST[@]}"; do firewall-cmd --add-port=$p/tcp --permanent >/dev/null 2>&1; done
        firewall-cmd --reload >/dev/null 2>&1
    fi
}
_run "Configuring OS Firewall" "_firewall_setup"

echo -e "\n${GRN}  [+] INSTALLATION COMPLETE!${RST}\n"
echo -e "${CYN}  [!] To view your complete Access List & URLs, please run:${RST}"
echo -e "${WHT}      sudo ./check-owasp-lab.sh${RST}\n"

tput cnorm
exit 0
