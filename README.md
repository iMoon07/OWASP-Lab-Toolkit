<div align="center">

<table><tr>
<td align="center" valign="middle">
<pre>
  \__/         \__/         \__/
  (oo)         (o-)         (@@)
 //||\\       //||\\       //||\\
  bug          bug          bug
             winking      hangover

  \__/         \__/         \__/
  (xx)         (--)         (OO)
 //||\\       //||\\       //||\\
  dead         bug          bug
   bug        sleep        female
</pre>
</td>
<td align="center" valign="middle">
<pre>
     く__,.ヘヽ.        /  ,ー､ 〉
          ＼ ', !-─‐-i  /  /´
          ／`ｰ'     L/／`ヽ､
        /   ／,  /|  ,  ,       ',
       ｲ   / /-‐/  ｉ  L_ ﾊ ヽ!   i
        ﾚ ﾍ 7ｲ`ﾄ  ﾚ'ｧ-ﾄ､!ハ|    |
         !,/7 '0'    ´0iソ|         |
         |.从"    _    ,,,, / |./    |
         ﾚ'| i＞.､,,__  _,.イ /   .i   |
          ﾚ'| | / k_７_/ﾚ'ヽ,  ﾊ.  |
            | |/i 〈|/  i  ,.ﾍ |  i  |
           .|/ /  ｉ：   ﾍ!    ＼  |
          kヽ>､ﾊ   _,.ﾍ､   /､!
           !'〈//`Ｔ´', ＼ `'7'ｰr'
           ﾚ'ヽL__|___i,___,ンﾚ|ノ
              ﾄ-,/  |___./
              'ｰ'    !_,.:
</pre>
</td>
</tr></table>

</div>

# OWASP LAB TOOLKIT v1.1

**A simple bash toolkit to deploy a Web Vulnerability Lab on Ubuntu Server. Perfect for beginners and teachers.**

<img src="./skull-hacking-time-4k-rh-2048x1152.jpg" alt="OWASP Lab Toolkit Cover" width="1000">

[![Platform](https://img.shields.io/badge/platform-Ubuntu%20Linux-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Targets](https://img.shields.io/badge/targets-11%20total-brightgreen?style=for-the-badge)](https://github.com/iMoon07/OWASP-Lab-Toolkit)

> Developed by [iMoon](https://www.linkedin.com/in/imoon07/) ([infosec-world.id](https://infosec-world.id)) · Inspired by [Taro Lay](https://www.linkedin.com/in/tarolay/)

---

## Changelog & Recent Updates

**[June 24, 2026] - v1.1 Core Rebuild**
- **Dynamic Custom Domain:** Enter your preferred domain (e.g., `lab.lokal` or `owasp.hacking`) during installation. The scripts will intelligently bind it to `/etc/hosts` and Nginx.
- **Web App Directory:** A simple HTML index page at your root domain to easily list and access all installed applications.
- **Nginx Reverse Proxy:** All traffic routes via port `80` & `443`, securely proxying internal apps (like Tomcat or Node.js) from backend ports (`127.0.0.1:8081`, etc).
- **Safe Uninstaller:** Safely cleans up the lab without aggressively wiping your existing `/var/www/html` folder.

---

## Included Applications

11 vulnerable and management applications built-in, accessible via subdomains (e.g., `http://dvwa.your-custom-domain.com`). 

> **Important:** To access these custom local domains from your Host OS (Attacker Machine) for a realistic feel, you MUST map the domains to your server's IP address in your local hosts file:
> - **Linux/Mac:** `/etc/hosts`
> - **Windows:** `C:\Windows\System32\drivers\etc\hosts`

| Application | Stack Engine | Local Domain Example |
|-------------|--------------|----------------------|
| [Mutillidae II](https://github.com/webpwnized/mutillidae) | PHP 8.3 | `mutillidae.owasp.hacking` |
| [DVWA](https://github.com/digininja/DVWA) | PHP 8.3 | `dvwa.owasp.hacking` |
| [bWAPP](https://github.com/iMoon07/bWAPPs) | PHP 8.3 | `bwapp.owasp.hacking` |
| [XVWA](https://github.com/s4n7h0/xvwa) | PHP 8.3 | `xvwa.owasp.hacking` |
| [VWA](https://github.com/hummingbirdscyber/Vulnerable-Web-Application) | PHP 8.3 | `vwa.owasp.hacking` |
| [Adminer](https://www.adminer.org/) | PHP 8.3 | `adminer.owasp.hacking` |
| [phpMyAdmin](https://www.phpmyadmin.net/) | PHP 8.3 | `phpmyadmin.owasp.hacking` |
| [Juice Shop](https://github.com/juice-shop/juice-shop) | Node.js | `juiceshop.owasp.hacking` |
| [WebGoat](https://github.com/WebGoat/WebGoat) | Java 21 | `webgoat.owasp.hacking` |
| [WebWolf](https://github.com/WebGoat/WebWolf) | Java 21 | `webwolf.owasp.hacking` |
| [Apache Tomcat](https://tomcat.apache.org/) | Java 21 | `tomcat.owasp.hacking` |

*(Note: `owasp.hacking` is the default. If you entered a custom domain like `lab.lokal`, your URLs will be `dvwa.lab.lokal`, `bwapp.lab.lokal`, etc.)*

---

## Core Infrastructure & Tools Stack

The toolkit automatically provisions the following stacks and helper utilities on your OS:

### Main Server Engines
| Component | Version | Role |
|-----------|---------|------|
| **Nginx** | `latest` | Front-door Router & SSL Proxy (Ports 80/443) |
| **Apache2** | `latest` | Backend Server for PHP Apps (Port 8081) |
| **PHP** | `8.3` | Execution Engine (Ondrej PPA) |
| **MySQL / MariaDB** | `11.4` | Primary Database (Official Repo) |
| **Node.js** | `20.x LTS` | JavaScript Engine (NodeSource) |
| **Java** | `Temurin JDK 21` | Java Environment (Adoptium) |

### Essential Ubuntu Packages & Helpers Used
- **Networking & Fetching:** `curl`, `wget`, `git`
- **Archives & Compression:** `tar`, `unzip`, `dpkg-dev`
- **Security & Firewalls:** `ufw`, `iptables`, `gnupg2`, `ca-certificates`
- **System Utils:** `python3`, `python3-pip`, `software-properties-common`, `apt-transport-https`

---

## Scripts Overview

| Script | Description |
|--------|-------------|
| `install-owasp-lab.sh` | Full installer — Builds the OS stack & deploys all targets. Prompts for custom domain. |
| `check-owasp-lab.sh` | Health checker — HTTP check, credentials list, and service monitor. |
| `uninstall-owasp-lab.sh` | Uninstaller — Safely wipes the lab and restores the OS without touching your other web root files. |

---

## Installation

> **Requires a fresh Ubuntu Server OS (22.04 / 24.04 LTS).**

1. Clone the repository:
```bash
git clone https://github.com/iMoon07/OWASP-Lab-Toolkit.git
cd OWASP-Lab-Toolkit
chmod +x *.sh
```

2. Run the core installer and follow the prompts:
```bash
sudo ./install-owasp-lab.sh
```

3. Verify installation:
```bash
sudo ./check-owasp-lab.sh
```
Or open the Web App Directory in your browser at the domain you configured.

---

## Script Details

- **`install-owasp-lab.sh`**: Installs OS stacks (Nginx, Apache, PHP, MariaDB, Node, Java), sets up a 4GB swap, configures apps natively in `/var/www/hack` & `/opt`, and automates DB provisioning and proxy routing.
- **`check-owasp-lab.sh`**: A CLI tool to check HTTP endpoints, print database credentials, display required `/etc/hosts` config, and monitor background services.
- **`uninstall-owasp-lab.sh`**: Safely wipes the lab by purging APT packages, killing daemons, and deleting cloned repos without destroying your existing `/var/www/html` root.


---

## WARNING
This toolkit provisions severely vulnerable applications and intentionally lowers system security limits (`allow_url_include = On`).
- **DO NOT** deploy this on a public-facing VPS or a production environment.
- It is designed **strictly for isolated, local Virtual Machines (VMs)** for educational purposes.
