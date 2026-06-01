# Ruckus R610 — Administration & Operations Reference

> **Device:** Ruckus R610 Unleashed AP | **Model:** 9U1-R610-WW00 | **MAC:** B479C803B000 | **Last updated:** June 2026

---

## Table of Contents

- [Ruckus R610 — Administration \& Operations Reference](#ruckus-r610--administration--operations-reference)
  - [Table of Contents](#table-of-contents)
  - [1. Device Overview](#1-device-overview)
  - [2. Initial Access](#2-initial-access)
    - [Find the AP's IP address](#find-the-aps-ip-address)
    - [Web UI login](#web-ui-login)
    - [SSH access](#ssh-access)
  - [3. Web UI — Key Sections](#3-web-ui--key-sections)
  - [4. CLI Access (SSH)](#4-cli-access-ssh)
  - [5. CLI Commands](#5-cli-commands)
    - [System information](#system-information)
    - [Network](#network)
    - [Radio \& Wi-Fi](#radio--wi-fi)
    - [Clients](#clients)
    - [PoE \& Power](#poe--power)
    - [Logs \& Events](#logs--events)
    - [Performance](#performance)
  - [6. Unleashed — Multi-AP Management](#6-unleashed--multi-ap-management)
  - [7. WLAN / SSID Configuration](#7-wlan--ssid-configuration)
  - [8. Radio Settings](#8-radio-settings)
  - [9. PoE \& Power Modes](#9-poe--power-modes)
  - [10. Client Management](#10-client-management)
  - [11. Diagnostics \& Troubleshooting](#11-diagnostics--troubleshooting)
    - [CLI diagnostics](#cli-diagnostics)
    - [Spectrum analysis (web UI)](#spectrum-analysis-web-ui)
    - [Packet capture (web UI)](#packet-capture-web-ui)
    - [Common issues](#common-issues)
  - [12. Firmware Management](#12-firmware-management)
  - [13. Config Backup \& Restore](#13-config-backup--restore)
  - [14. Factory Reset](#14-factory-reset)
  - [Quick Reference — Daily Health Check](#quick-reference--daily-health-check)
  - [Quick Reference — Troubleshooting Checklist](#quick-reference--troubleshooting-checklist)
  - [HK Office — AP Reference](#hk-office--ap-reference)

---

## 1. Device Overview

| Item | Detail |
|---|---|
| Model | Ruckus R610 |
| Part number | 9U1-R610-WW00 |
| Serial number | 391048003276 |
| MAC address | B479C803B000 |
| Wi-Fi standard | 802.11ac Wave 2 (Wi-Fi 5) |
| Bands | Dual-band — 2.4 GHz + 5 GHz |
| Spatial streams | 2x2:2 on 2.4 GHz / 4x4:4 on 5 GHz |
| Max throughput | 300 Mbps (2.4 GHz) + 1733 Mbps (5 GHz) |
| PoE requirement | 802.3af (15.4W) — standard PoE |
| Controller mode | Unleashed (controller-less) |
| Default IP | 192.168.0.1 |
| Manufactured | 2018 |

---

## 2. Initial Access

### Find the AP's IP address

**Option 1 — Check DHCP leases on HP V1910:**
```bash
display arp
# Look for MAC B479C803B000
```

**Option 2 — Check DHCP server (SonicWall):**
```
show dhcp server lease
# Look for Ruckus or the MAC address
```

**Option 3 — Direct connection (if IP unknown):**
```
Connect laptop directly to AP ethernet port
Set PC IP  : 192.168.0.2
Subnet mask: 255.255.255.0
Gateway    : 192.168.0.1
Browser    : https://192.168.0.1
```

### Web UI login

```
URL      : https://<ap-ip-address>
Username : admin
Password : (set during first-time setup)
```

> **Note:** In Unleashed mode, you always log into the **Master AP** — whichever AP is currently elected as master hosts the web UI for all APs in the cluster.

### SSH access

```
ssh admin@<ap-ip-address>
Port: 22
```

---

## 3. Web UI — Key Sections

| Section | What it shows |
|---|---|
| **Dashboard** | Overall AP health, client count, throughput |
| **Access Points** | All APs in Unleashed cluster, status, model |
| **Clients** | All connected Wi-Fi clients — IP, MAC, signal, band |
| **WLANs** | SSID configuration — name, security, VLAN |
| **Admin** | System settings, firmware, backup, syslog |
| **Troubleshooting** | Ping, traceroute, packet capture, spectrum analysis |

---

## 4. CLI Access (SSH)

```bash
ssh admin@<ap-ip-address>
```

**Enter privileged shell (rkscli):**
```
login: admin
Password: <your-password>
rkscli:
```

**Enter Linux shell (advanced — use with caution):**
```bash
rkscli: !v54!
#
```

---

## 5. CLI Commands

### System information

| Command | Description |
|---|---|
| `get version` | Firmware version and build number |
| `get model` | AP model and hardware revision |
| `get serial` | AP serial number |
| `get mac` | AP MAC address |
| `get uptime` | System uptime |
| `get sysinfo` | Full system information summary |
| `get director` | Which AP is currently the Unleashed master |

### Network

| Command | Description |
|---|---|
| `get ip` | AP IP address, subnet, gateway |
| `get dns` | DNS server configuration |
| `get vlan` | VLAN configuration |
| `get route` | Routing table |
| `get arp` | ARP table — connected devices |

### Radio & Wi-Fi

| Command | Description |
|---|---|
| `get radio` | Radio configuration — band, channel, power |
| `get wlan` | All configured WLANs (SSIDs) |
| `get wlanlist` | Summary list of WLANs |
| `get channel` | Current channel assignment on each radio |
| `get txpower` | Current transmit power settings |
| `get noise` | RF noise floor per radio |
| `get channelstats` | Channel utilisation statistics |

### Clients

| Command | Description |
|---|---|
| `get client` | All currently connected clients |
| `get client detail` | Detailed client info — signal, MCS rate, band |
| `get client count` | Number of connected clients per radio |
| `get station` | Alternative command for client list |

### PoE & Power

| Command | Description |
|---|---|
| `get power-mode` | Current PoE power mode (802.3af / 802.3at) |
| `get power` | Power budget and current draw |

### Logs & Events

| Command | Description |
|---|---|
| `get log` | Recent system log entries |
| `get alarm` | Current active alarms |
| `get event` | Event history |
| `get syslog` | Syslog server configuration |

### Performance

| Command | Description |
|---|---|
| `get throughput` | Current throughput per radio |
| `get stats` | General statistics — packets, bytes, errors |
| `get meshstats` | Mesh link statistics (if mesh is configured) |

---

## 6. Unleashed — Multi-AP Management

The R610 runs in **Unleashed** mode — no external controller needed. One AP acts as the **Master**, others are **Members**.

| Command | Description |
|---|---|
| `get director` | Shows which AP is the current Unleashed master |
| `get aplist` | All APs in the Unleashed cluster |
| `get apstats` | Per-AP statistics across the cluster |
| `get mesh` | Mesh topology (if configured) |

**Unleashed master election:**
- The master AP hosts the web UI for the whole cluster
- If the master AP goes offline, another AP is elected automatically
- Adding a new AP: connect it to the same network and it will auto-join

**Adding a new AP (e.g. R650) to existing Unleashed cluster:**
1. Connect new AP to the same LAN/VLAN as R610
2. Power on — it will discover the existing Unleashed master automatically
3. Log into master web UI → **Access Points** → approve the new AP
4. New AP will pull config from the master

---

## 7. WLAN / SSID Configuration

**View all SSIDs:**
```bash
get wlan
```

**Via web UI — create/edit SSID:**
```
WLANs → Create New
  Name (SSID)     : e.g. ASIFMA-Office
  Type            : Standard Usage
  Authentication  : WPA2-Personal or WPA2-Enterprise
  Encryption      : AES
  Passphrase      : (set a strong password)
  VLAN            : (assign if using VLAN segmentation)
```

**Guest WLAN (isolated from LAN):**
```
WLANs → Create New
  Type            : Guest Access
  Isolation       : Enable client isolation
  VLAN            : separate guest VLAN
```

---

## 8. Radio Settings

**View current radio config:**
```bash
get radio
get channel
get txpower
```

**Recommended settings for office environment:**

| Setting | 2.4 GHz | 5 GHz |
|---|---|---|
| Channel width | 20 MHz | 80 MHz |
| Channel (HK) | 1, 6, or 11 | 36, 40, 44, 48, 149–161 |
| Tx power | Auto or medium | Auto |
| Min RSSI | -80 dBm | -75 dBm |

> **Tip:** Let Ruckus ChannelFly auto-select channels — it continuously monitors and switches to less congested channels. Enable under **Access Points → Radio Settings → ChannelFly**.

---

## 9. PoE & Power Modes

The R610 operates on **802.3af (15.4W)** — no restrictions, full functionality.

**Check current power mode:**
```bash
get power-mode
```

**Expected output on HP V1910 (802.3af):**
```
Power Mode: 802.3af
All features: ENABLED
```

> **Note for future R650/R670 upgrade:**
> The R650 requires 802.3at (PoE+) for full performance.
> The HP V1910-24G only does 802.3af.
> Solution: use a **Ruckus 60W PoE injector (902-0180)** between the switch and the new AP.

---

## 10. Client Management

**View connected clients:**
```bash
get client
```

**Disconnect a client (via web UI):**
```
Clients → select client → Disconnect
```

**Block a client by MAC:**
```
Admin → Access Control → Blacklist
Add MAC address → Apply
```

**View client signal quality:**
```bash
get client detail
# Look for RSSI value:
# > -65 dBm  = Excellent
# -65 to -75 = Good
# -75 to -85 = Fair
# < -85 dBm  = Poor — client too far from AP
```

---

## 11. Diagnostics & Troubleshooting

### CLI diagnostics

```bash
# Ping from AP
ping 8.8.8.8

# Ping with source interface
ping -I eth0 8.8.8.8

# Traceroute
traceroute 8.8.8.8

# Check RF environment
get noise
get channelstats

# Check for interference
get radio
```

### Spectrum analysis (web UI)

```
Troubleshooting → Spectrum Analysis
Select radio (2.4 GHz or 5 GHz)
Run scan → view interference sources
```

### Packet capture (web UI)

```
Troubleshooting → Packet Capture
Select interface → Start
Download .pcap file → open in Wireshark
```

### Common issues

| Issue | Check |
|---|---|
| AP not reachable | `display poe interface` on HP V1910 — is port powered? |
| Clients dropping | `get client detail` — RSSI below -75? AP too far away |
| Slow speeds on 5 GHz | `get channel` — interference? Try different channel |
| Cannot join cluster | Same VLAN/subnet as master? Firewall blocking UDP 12222? |
| Web UI not loading | Is this AP the master? `get director` to confirm |
| High channel utilisation | `get channelstats` — enable ChannelFly for auto-selection |

---

## 12. Firmware Management

**Check current firmware:**
```bash
get version
```

**Update via web UI:**
```
Admin → Upgrade
Upload firmware .img file → Apply
```

**Latest firmware:** Check https://support.ruckuswireless.com

> ⚠️ **Do not mix incompatible firmware versions** across APs in an Unleashed cluster. All APs must run the same firmware version.

**Upgrade process for Unleashed cluster:**
1. Download firmware from Ruckus support portal
2. Upload to master AP via web UI
3. Master upgrades first, then pushes to all member APs automatically
4. Cluster will be briefly offline (~5 min) during upgrade

---

## 13. Config Backup & Restore

**Backup via web UI:**
```
Admin → Backup → Download Backup
Saves as .bak file — store securely
```

**Restore via web UI:**
```
Admin → Restore → Upload backup file
```

**CLI backup:**
```bash
copy startup-config tftp://<tftp-server-ip>/R610_backup.cfg
```

---

## 14. Factory Reset

**Method 1 — Reset button (physical):**
```
1. Locate reset pinhole on back of AP
2. Insert paperclip — hold for 10 seconds
3. Release — AP reboots to factory defaults
4. Wait 3-5 minutes for full boot
5. Connect to default IP: https://192.168.0.1
```

**Method 2 — CLI:**
```bash
set factory
# Confirm when prompted
reboot
```

> ⚠️ **Factory reset removes all configuration.**
> Back up the config first if you need to restore the SSID and settings.
> After reset, you will need to reconfigure the Unleashed cluster from scratch.

---

## Quick Reference — Daily Health Check

```bash
get version          # firmware version
get uptime           # how long has it been running?
get client count     # number of connected clients
get radio            # radio status and channel
get noise            # RF noise floor
get alarm            # any active alarms?
get director         # confirm which AP is master
```

---

## Quick Reference — Troubleshooting Checklist

```bash
# AP not responding
# → Check PoE port on HP V1910
display poe interface GigabitEthernet 1/0/X   # on switch
display interface GigabitEthernet 1/0/X        # link up?

# Clients cannot connect to SSID
get wlan             # is SSID broadcasting?
get radio            # is radio up?
get client           # is client attempting to associate?

# Slow Wi-Fi performance
get channelstats     # channel busy?
get noise            # high noise floor?
get client detail    # poor RSSI?
get throughput       # actual throughput figures

# AP not joining Unleashed cluster
get director         # who is master?
get aplist           # is AP visible in cluster?
ping <master-ap-ip>  # can AP reach master?
# Check: same VLAN? UDP 12222 open?
```

---

## HK Office — AP Reference

| Item | Detail |
|---|---|
| AP model | Ruckus R610 |
| Mode | Unleashed (controller-less) |
| Connected to | HP V1910-24G (port unknown — check `display poe interface`) |
| PoE source | HP V1910-24G — 802.3af ✓ |
| Default IP | 192.168.0.1 |
| Planned upgrade | Ruckus R650 (Wi-Fi 6) or R670 (Wi-Fi 7) |
| PoE note | R650/R670 needs 802.3at — use Ruckus 60W injector (902-0180) |

---

*Document maintained by: IT / Network Engineering*
*Reference: Ruckus Unleashed User Guide — support.ruckuswireless.com*
