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

# 🛡️ OWASP LAB TOOLKIT v1.0

**A simple bash toolkit to deploy a Web Vulnerability Lab on Ubuntu Server. Perfect for beginners and teachers. It automatically installs 9 vulnerable applications (containing 401 vulnerabilities), the required server stack, and custom local domains for safe hacking practice.**

### 🐛 Practice Exploiting:
`SQL Injection (SQLi)` · `Cross-Site Scripting (XSS)` · `Command Injection` · `LFI / RFI` · `CSRF` · `SSRF` · `IDOR` · `XXE` · `Broken Access Control` · `Security Misconfigurations` · *and hundreds more...*

> ⚠️ **Requires a fresh Ubuntu Server OS.** You can download it at: [ubuntu.com/download/server](https://ubuntu.com/download/server)

[![Platform](https://img.shields.io/badge/platform-Ubuntu%20Linux-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com/)
[![Targets](https://img.shields.io/badge/targets-9%20total-brightgreen?style=for-the-badge)](https://github.com/iMoon07/OWASP-Lab-Toolkit)
[![Scripts](https://img.shields.io/badge/scripts-4-blue?style=for-the-badge)](https://github.com/iMoon07/OWASP-Lab-Toolkit)
[![Tutorial](https://img.shields.io/badge/tutorial-YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=yzi524y9Tbk)

> Developed by [iMoon](https://www.linkedin.com/in/imoon07/) ([infosec-world.id](https://infosec-world.id)) · Inspired by [Taro Lay](https://www.linkedin.com/in/tarolay/)

**Looking for offensive tools to attack this lab?** Check out the [Bugbounty Toolkit](https://github.com/iMoon07/bugbounty-toolkit).

</div>

---

## 📁 Scripts Overview

| Script | Description |
|--------|-------------|
| [`install-owasp-lab.sh`](#-installation) | Full installer — Builds the OS stack & deploys all vulnerable targets |
| [`check-owasp-lab.sh`](#-health-check) | Health checker — Live HTTP check & service monitor |
| [`update-owasp-lab.sh`](#-updating) | Updater — Pulls latest Github repos & rebuilds databases |
| [`uninstall-owasp-lab.sh`](#-uninstallation) | Uninstaller — Safely wipes the entire lab and restores the OS |

> ⚠️ **Currently Ubuntu Linux only.** Tested on Ubuntu 22.04 LTS and 24.04 LTS. <br>
> *Next updates will include support for Fedora (RPM) and Debian.*

---

## 🎯 The Hacking Like A Pro in Dojo — 9 Vulnerable Apps

> Accessed via custom local domains for a realistic feel. Requires mapping the domains to your attacker's `/etc/hosts` file.

| Application | Engine | Local Domain | 
|-------------|--------|--------------|
| [Mutillidae II](https://github.com/webpwnized/mutillidae) | PHP 8.3 | `mutillidae.owasp.hacking` | 
| [DVWA](https://github.com/digininja/DVWA) | PHP 8.3 | `dvwa.owasp.hacking` |
| [bWAPP](https://github.com/iMoon07/bWAPPs) | PHP 8.3 | `bwapp.owasp.hacking` |
| [XVWA](https://github.com/s4n7h0/xvwa) | PHP 8.3 | `xvwa.owasp.hacking` | 
| [VWA](https://github.com/hummingbirdscyber/Vulnerable-Web-Application) | PHP 8.3 | `vwa.owasp.hacking` | 
| [Juice Shop](https://github.com/juice-shop/juice-shop) | Node.js | `juiceshop.owasp.hacking` | 
| [WebGoat](https://github.com/WebGoat/WebGoat) | Java 21 | `webgoat.owasp.hacking` | 
| [WebWolf](https://github.com/WebGoat/WebWolf) | Java 21 | `webwolf.owasp.hacking` | 
| [Apache Tomcat](https://tomcat.apache.org/) | Java 21 | `tomcat.owasp.hacking` | 

---

## ⚙️ Core Infrastructure Stack

Installed automatically via PPAs and official sources. Managed by `systemctl`.

| Stack Component | Version Detail |
|-----------------|----------------|
| **Nginx** | `latest` (Front-door Router) |
| **Apache2** | `latest` (Backend PHP Server) |
| **PHP** | `PHP 8.3` (Ondrej PPA) |
| **MariaDB** | `MariaDB 11.4` (Official Repo) |
| **Node.js** | `Node 20.x LTS` (NodeSource) |
| **Java** | `Temurin JDK 21` (Adoptium) |

---

## 🚀 Installation & Usage

> 📺 **Video Tutorial:** Watch the full step-by-step setup guide on YouTube: [https://www.youtube.com/watch?v=yzi524y9Tbk](https://www.youtube.com/watch?v=yzi524y9Tbk)

### 1. Prerequisites
- **OS:** Ubuntu 22.04 / 24.04 LTS (`root` / `sudo` access required)
- **Hardware:** Minimum 2GB RAM (4GB Recommended), 1 vCPU, 20 GB Disk Space.

### 2. Deployment
Clone the repository and run the core installer:
```bash
git clone https://github.com/iMoon07/OWASP-Lab-Toolkit.git
cd OWASP-Lab-Toolkit
chmod +x *.sh

sudo ./install-owasp-lab.sh
```

### 3. Verification
Run the Check Script to verify all services are active and responding with `HTTP 200 OK`:
```bash
sudo ./check-owasp-lab.sh
```

---

## ⚠️ Disclaimer
**WARNING:** This toolkit provisions severely vulnerable applications, configures weak database credentials, and intentionally lowers system security limits (`allow_url_include = On`).
- **DO NOT** deploy this on a public-facing VPS or a production environment.
- It is designed **strictly for isolated, local Virtual Machines (VMs)** for educational and penetration testing research purposes.

---
*If you find this toolkit useful for your hacking studies, don't forget to star the repository!* ⭐
