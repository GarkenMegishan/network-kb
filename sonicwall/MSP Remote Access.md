# SonicWall NSA 3600 — MSP Remote Access Configuration

> **Scope:** Allow MSP (Managed Service Provider) secure remote access to SonicWall NSA 3600
> **Last updated:** June 2026

---

## Table of Contents

1. [Overview & Access Methods](#1-overview--access-methods)
2. [Method 1 — SonicWall Cloud Management (Recommended)](#2-method-1--sonicwall-cloud-management-recommended)
3. [Method 2 — Site-to-Site VPN](#3-method-2--site-to-site-vpn)
4. [Method 3 — SSL-VPN with MSP User Account](#4-method-3--ssl-vpn-with-msp-user-account)
5. [Method 4 — HTTPS Management Access on WAN](#5-method-4--https-management-access-on-wan)
6. [Restrict Management Access by IP](#6-restrict-management-access-by-ip)
7. [Create a Dedicated MSP Admin Account](#7-create-a-dedicated-msp-admin-account)
8. [Audit & Logging for MSP Access](#8-audit--logging-for-msp-access)
9. [Security Hardening Checklist](#9-security-hardening-checklist)
10. [Verification Commands](#10-verification-commands)

---

## 1. Overview & Access Methods

There are four ways to give an MSP remote access to a SonicWall.
Choose based on your security requirements:

| Method | Security | Complexity | Best For |
|---|---|---|---|
| SonicWall Cloud Management (NSM) | ⭐⭐⭐⭐⭐ | Low | Recommended — no open ports needed |
| Site-to-Site VPN | ⭐⭐⭐⭐⭐ | Medium | MSP has fixed office IP |
| SSL-VPN + MSP account | ⭐⭐⭐⭐ | Medium | MSP engineers work remotely |
| HTTPS WAN access (IP-restricted) | ⭐⭐⭐ | Low | Quick setup, higher exposure |

> ⚠️ **Never open HTTPS management to `any` on the WAN interface.**
> Always restrict to the MSP's static IP address(es).

---

## 2. Method 1 — SonicWall Cloud Management (Recommended)

**SonicWall Network Security Manager (NSM)** allows the MSP to manage
your firewall via the cloud — no inbound ports need to be opened on your WAN.
The SonicWall initiates an outbound connection to Sonicwall's cloud.

### How it works
```
SonicWall NSA 3600
    ↓ outbound HTTPS (port 443)
SonicWall NSM Cloud (manage.sonicwall.com)
    ↑ MSP logs in via browser
MSP Engineer
```

### Enable NSM on the SonicWall (CLI)

```bash
# Check current cloud management status
show management

# Enable SonicWall cloud management
configure
  management cloud enable
end
```

### Enable NSM via Web UI

```
Device → Settings → SonicWall Services → Cloud Management
  Enable Cloud Management: ON
  Register device with your SonicWall MySonicWall account
```

### MSP Steps

```
1. MSP creates a MySonicWall account at mysonicwall.com
2. You add the MSP's account as a tenant/sub-account in NSM
3. MSP logs into manage.sonicwall.com
4. Your NSA 3600 appears in their device list
5. MSP can push config, view logs, manage policies — no VPN needed
```

> **Advantage:** The SonicWall only makes outbound connections —
> no inbound firewall rules or open ports required.
> This is the most secure and MSP-friendly option.

---

## 3. Method 2 — Site-to-Site VPN

Best when the MSP has a **fixed office with a static IP** and their own firewall.
Creates an encrypted tunnel between your HK office and the MSP's network.

### Network assumptions

```
HK SonicWall WAN IP : <your-pccw-public-ip>
MSP WAN IP          : <msp-static-public-ip>
HK LAN              : 10.10.0.0/16
MSP LAN             : 172.16.0.0/24  (example — confirm with MSP)
```

### Step 1 — Create Address Objects

```
Network → Address Objects → Add

Object 1:
  Name     : MSP-WAN-IP
  Type     : Host
  IP       : <msp-static-public-ip>
  Zone     : WAN

Object 2:
  Name     : MSP-LAN-Subnet
  Type     : Network
  IP       : 172.16.0.0
  Mask     : 255.255.255.0
  Zone     : VPN

Object 3:
  Name     : HK-LAN-All
  Type     : Network
  IP       : 10.10.0.0
  Mask     : 255.255.0.0
  Zone     : LAN
```

### Step 2 — Create VPN Policy (CLI)

```bash
# Via CLI — Site-to-Site IKEv2 VPN to MSP
configure

vpn policy
  name MSP-SITE-TO-SITE
  auth-method preshared-key
  preshared-key <use-a-strong-random-key-min-32-chars>
  ike-version 2
  local-gateway <your-sonicwall-wan-ip>
  remote-gateway <msp-static-public-ip>
  local-network 10.10.0.0/16
  remote-network 172.16.0.0/24
  phase1
    encryption aes256
    authentication sha256
    dh-group 14
    lifetime 28800
  phase2
    encryption aes256
    authentication sha256
    pfs-group 14
    lifetime 3600
  enable
exit

end
```

### Step 3 — Firewall Rule to allow MSP VPN access to management

```
Firewall → Access Rules → Add Rule

Rule 1 — Allow MSP to manage SonicWall:
  From     : VPN
  To       : THIS FIREWALL (MGMT)
  Source   : MSP-LAN-Subnet
  Dest     : Firewalled Subnets
  Service  : HTTPS, SSH
  Action   : Allow
  Comment  : MSP Management Access via VPN

Rule 2 — Allow MSP to reach LAN for monitoring:
  From     : VPN
  To       : LAN
  Source   : MSP-LAN-Subnet
  Dest     : HK-LAN-All
  Service  : HTTPS, SSH, SNMP, Ping
  Action   : Allow
  Comment  : MSP Monitoring Access
```

### Step 4 — Share VPN details with MSP

```
Provide to MSP:
  - Your SonicWall WAN IP
  - Pre-shared key (share via secure channel — not email)
  - Local network: 10.10.0.0/16
  - IKE version: 2
  - Encryption: AES-256 / SHA-256 / DH Group 14
  - Phase 1 lifetime: 28800
  - Phase 2 lifetime: 3600
```

---

## 4. Method 3 — SSL-VPN with MSP User Account

Best when MSP engineers **work from different locations** (no fixed IP).
Each MSP engineer connects via SonicWall's SSL-VPN client (NetExtender).

### Step 1 — Enable SSL-VPN Server

```
VPN → SSL-VPN → Server Settings

  Enable SSL-VPN : ON
  Port           : 4433  (change from default 443 to reduce scan noise)
  Certificate    : Use your HTTPS certificate
  DNS Server 1   : 8.8.8.8
  DNS Server 2   : 8.8.4.4
```

### Step 2 — Create MSP User Group

```
Users → Local Groups → Add Group

  Group Name  : MSP-Remote-Access
  Description : MSP engineers remote access group
  VPN Access  : Add → MSP-Management-Network (address object)
```

### Step 3 — Create MSP User Accounts

```
Users → Local Users → Add User

  Username    : msp-engineer-01
  Password    : <strong-password>          ← share via secure channel
  Group       : MSP-Remote-Access
  VPN Access  : Inherit from group

  Repeat for each MSP engineer
```

### Step 4 — Create SSL-VPN Client Address Range

```
Network → Address Objects → Add

  Name  : SSL-VPN-MSP-Pool
  Type  : Range
  Start : 192.168.200.10
  End   : 192.168.200.30
  Zone  : VPN
```

### Step 5 — Create SSL-VPN Client Profile

```
VPN → SSL-VPN → Client Settings → Add

  Profile Name        : MSP-Access
  User Group          : MSP-Remote-Access
  Virtual IP Pool     : SSL-VPN-MSP-Pool
  DNS Server          : 8.8.8.8
  Enable Split Tunnel : ON
    Routes to tunnel  : 10.10.0.0/16 (HK LAN only — not all traffic)
```

### Step 6 — Firewall Rule for SSL-VPN to Management

```
Firewall → Access Rules → Add

  From    : SSL VPN
  To      : THIS FIREWALL
  Source  : MSP-Remote-Access (group)
  Service : HTTPS (443), SSH (22)
  Action  : Allow
  Comment : MSP SSL-VPN to SonicWall Management
```

### Step 7 — Provide MSP with NetExtender details

```
Send to MSP (via secure channel):
  SSL-VPN URL  : https://<your-wan-ip>:4433
  Username     : msp-engineer-01
  Password     : <password>
  Download     : NetExtender client from sonicwall.com/products/remote-access
```

---

## 5. Method 4 — HTTPS Management Access on WAN

Quickest method — allows the MSP to access the SonicWall web UI
directly over the internet. **Must be restricted to MSP's static IP only.**

> ⚠️ **Only use this if the MSP has a static IP.**
> If their IP is dynamic, use SSL-VPN (Method 3) instead.

### Step 1 — Create MSP IP Address Object

```
Network → Address Objects → Add

  Name : MSP-Office-IP
  Type : Host
  IP   : <msp-static-public-ip>
  Zone : WAN
```

### Step 2 — Enable HTTPS on WAN interface (restricted)

```bash
# CLI
configure
  interface X1
    management https
    management ssh
    management ping
  exit
end
```

Or via Web UI:
```
Network → Interfaces → WAN (X1) → Edit
  Management:
    ☑ HTTPS
    ☑ SSH
    ☐ Ping  (optional — disable to reduce fingerprinting)
  User Login:
    ☐ HTTP
    ☑ HTTPS
```

### Step 3 — Restrict WAN management to MSP IP only

```
Firewall → Access Rules → Add Rule

  Name    : Allow-MSP-HTTPS-Management
  From    : WAN
  To      : THIS FIREWALL (MGMT)
  Source  : MSP-Office-IP
  Dest    : Any
  Service : HTTPS, SSH
  Action  : Allow
  Priority: Put ABOVE the default WAN→MGMT deny rule
  Comment : MSP management access — restricted to MSP static IP

! Add a second rule to explicitly deny all other WAN management:
  Name    : Deny-WAN-Management-All
  From    : WAN
  To      : THIS FIREWALL (MGMT)
  Source  : Any
  Service : HTTPS, SSH, HTTP
  Action  : Deny
  Logging : Enable
  Comment : Block all other WAN management attempts
```

### Step 4 — Provide MSP with access details

```
Send to MSP (via secure channel):
  URL      : https://<your-wan-ip>
  Username : msp-admin  (dedicated account — see section 7)
  Password : <strong-password>
  Note     : Access only works from MSP office IP <msp-static-ip>
```

---

## 6. Restrict Management Access by IP

Regardless of which method you choose, always restrict
management access to known IPs. Apply this to all methods:

```bash
# CLI — restrict SSH and HTTPS management to specific IPs

configure

  ! Create access rule — allow MSP IP to manage firewall
  access-rule
    from WAN to FIREWALLED_SUBNETS
    source MSP-Office-IP
    destination any
    service group MGMT-SERVICES
    action allow
    comment "MSP management access"
  exit

  ! Explicitly deny all other management from WAN
  access-rule
    from WAN to FIREWALLED_SUBNETS
    source any
    destination any
    service group MGMT-SERVICES
    action deny
    logging enable
    comment "Block all other WAN management"
  exit

end
```

**Create MGMT-SERVICES service group:**
```
Network → Service Objects → Service Groups → Add

  Name     : MGMT-SERVICES
  Members  : HTTPS (TCP 443), SSH (TCP 22), HTTP (TCP 80)
```

---

## 7. Create a Dedicated MSP Admin Account

Never share your primary `admin` account with the MSP.
Create a dedicated account with appropriate privileges.

### Via Web UI

```
Device → Administration → Users → Add User

  Username     : msp-admin
  Password     : <generate strong password — min 16 chars>
  Privileges   : Limited Administrator
    ☑ Manage Firewall Policies
    ☑ View Logs
    ☑ Manage VPN
    ☐ Manage Admin Accounts     ← do NOT grant this
    ☐ Factory Reset             ← do NOT grant this
    ☐ Firmware Upgrade          ← grant only if MSP manages firmware
  Comment      : MSP remote management account
```

### Via CLI

```bash
configure
  user local msp-admin
    password <strong-password>
    privilege limited-admin
    comment "MSP management account"
  exit
end
```

### Admin privilege levels

| Level | Access | Recommended For |
|---|---|---|
| `Administrator` | Full access including reset, firmware | Internal IT only |
| `Limited Administrator` | Policies, VPN, logs — no user mgmt | MSP day-to-day |
| `Guest Administrator` | Read-only — view config and logs | MSP audits / reporting |
| `Read-Only` | View everything, change nothing | Compliance auditors |

> **Recommendation:** Give MSP `Limited Administrator` for day-to-day management.
> If MSP only needs to monitor (not change config), use `Read-Only`.

---

## 8. Audit & Logging for MSP Access

Track every action the MSP takes on the firewall.

### Enable admin activity logging

```
Device → Log → Settings
  ☑ Log Administrator Activity
  ☑ Log Configuration Changes
  ☑ Log Login/Logout Events
  ☑ Log Failed Login Attempts
```

### Send logs to your syslog server

```bash
# CLI
configure
  log syslog enable
  log syslog server 10.10.99.100    ! your management server
  log syslog port 514
  log syslog format default
end
```

### Via Web UI

```
Device → Log → Syslog
  Syslog Server   : 10.10.99.100
  Port            : 514
  Syslog Format   : Default
  Enable Syslog   : ON
```

### View MSP login activity (CLI)

```bash
# Show recent admin logins
show event-log | include msp-admin
show event-log | include login
show event-log | include config

# Show all config changes
show event-log category configuration
```

### Set up login notifications (Web UI)

```
Device → Administration → Advanced
  Email Alerts:
    ☑ Alert on administrator login
    ☑ Alert on configuration change
    Alert email : your-it-team@company.com
```

---

## 9. Security Hardening Checklist

Apply these regardless of which remote access method you choose:

```
☐ Create dedicated msp-admin account — never share admin credentials
☐ Set account timeout — admin session expires after 15 minutes idle
☐ Enable MFA on MySonicWall account (for NSM cloud method)
☐ Restrict management access to MSP static IP only
☐ Disable HTTP management on all interfaces (HTTPS only)
☐ Disable Telnet — use SSH only
☐ Change SSL-VPN port from 443 to custom port (e.g. 4433)
☐ Enable login attempt lockout (lock after 5 failed attempts)
☐ Enable audit logging and send to syslog server
☐ Set up email alerts for admin logins and config changes
☐ Review MSP access logs monthly
☐ Rotate MSP account password quarterly
☐ Document MSP access method and IP in your network KB
☐ Define off-boarding process if MSP contract ends
```

### Set session timeout and login lockout

```
Device → Administration → Settings

  Administrator Inactivity Timeout : 15 minutes
  Login Security:
    Max Failed Login Attempts : 5
    Lockout Period            : 30 minutes
    ☑ Enable CAPTCHA after failed logins
```

### Disable insecure management protocols

```bash
configure
  interface X0
    no management http
    no management telnet
    management https
    management ssh
  exit
  interface X1
    no management http
    no management telnet
  exit
end
```

---

## 10. Verification Commands

### Check management access settings

```bash
show management
show interface X1 | include management
```

### Check active admin sessions

```bash
show user active
show user active admin
```

### Check VPN tunnel (if using site-to-site)

```bash
show vpn
show vpn tunnel
show vpn phase1
show vpn phase2
ping <msp-lan-ip> source X0
```

### Check SSL-VPN sessions (if using SSL-VPN)

```bash
show ssl-vpn
show vpn ssl list
```

### Check access rules

```bash
show access-rule from WAN to FIREWALLED_SUBNETS
```

### Check login audit log

```bash
show event-log
show event-log | include msp-admin
show event-log | include login
```

### Test MSP access from your side

```bash
! Ping MSP office IP to confirm reachability
ping <msp-static-public-ip>

! Check ARP — MSP connected via VPN?
show arp | include <msp-vpn-ip>
```

---

## Recommended Setup for HK Office MSP

Based on your environment (PCCW internet, SonicWall NSA 3600, financial firm):

```
Primary method   : Method 1 — SonicWall NSM Cloud Management
                   No inbound ports opened, MSP manages via cloud
                   Most secure for a financial environment

Backup method    : Method 3 — SSL-VPN with dedicated MSP accounts
                   For break-glass scenarios or if NSM is unavailable
                   Restrict to MSP engineer accounts with MFA

Account setup    : Dedicated msp-admin (Limited Administrator)
                   Read-only account for MSP monitoring/reporting

Logging          : All admin actions logged to syslog → 10.10.99.100
                   Email alerts to IT team on every admin login

Review cadence   : Monthly log review of MSP activity
                   Quarterly password rotation for MSP accounts
```

---

## MSP Handover Checklist

Information to provide to the MSP securely:

```
☐ SonicWall WAN IP address
☐ MySonicWall account credentials (for NSM) — via password manager
☐ SSL-VPN URL and port (if using Method 3)
☐ MSP user account credentials — via password manager or 1Password
☐ VPN pre-shared key (if site-to-site) — never via email
☐ Emergency console access procedure (physical console details)
☐ Your escalation contact name and number
☐ Maintenance window schedule
☐ Change management process — what requires your approval before changes
```

> 🔴 **Never send passwords, pre-shared keys, or VPN credentials via email or chat.**
> Use a secure password manager (1Password, Bitwarden) or an encrypted file transfer.

---

*Document maintained by: IT / Network Engineering*
*Reference: SonicWall NSA Administration Guide — docs.sonicwall.com*
