# HP V1910-24G (JE006A) — CLI Command Reference

> **Device:** HP V1910-24G Switch (JE006A) | **Console:** 9600 8N1 | **Last updated:** June 2026

---

## Table of Contents

1. [Console Access](#1-console-access)
2. [System Info](#2-system-info)
3. [Interface & Port Status](#3-interface--port-status)
4. [VLAN](#4-vlan)
5. [MAC Address Table](#5-mac-address-table)
6. [Spanning Tree](#6-spanning-tree)
7. [ARP & IP](#7-arp--ip)
8. [PoE Management](#8-poe-management)
9. [Link Aggregation (LACP)](#9-link-aggregation-lacp)
10. [SNMP](#10-snmp)
11. [Logging & Events](#11-logging--events)
12. [User & Security](#12-user--security)
13. [Config Management](#13-config-management)
14. [Diagnostics](#14-diagnostics)

---

## 1. Console Access

```
Baud rate : 9600
Data bits : 8
Parity    : None
Stop bits : 1
Flow ctrl : None
```

**PuTTY (Windows):** Select `Serial` → enter COM port → set speed to `9600`

**Mac/Linux:**
```bash
screen /dev/tty.usbserial 9600
```

**Default credentials:**
```
Username : admin
Password : (blank — press Enter)
```

> **Note:** The V1910 runs Comware OS (H3C-based), not Cisco IOS.
> The CLI syntax is similar to H3C/HP Comware — not SonicWall or Cisco.

**Enter system view (required before most config commands):**
```
<HP>  system-view
[HP]  (now in system view)
```

**Return to user view:**
```
[HP]  quit
```

---

## 2. System Info

| Command | Description |
|---|---|
| `display version` | Firmware version, model, uptime, hardware revision |
| `display device` | Hardware component status — PSU, fans, modules |
| `display cpu-usage` | Current CPU utilisation percentage |
| `display memory` | Memory usage and available free memory |
| `display environment` | Temperature and hardware health status |
| `display clock` | Current system date and time |
| `display current-configuration` | Full running configuration |
| `display saved-configuration` | Last saved configuration |

```bash
# Quick system health check
display version
display device
display cpu-usage
display memory
```

---

## 3. Interface & Port Status

| Command | Description |
|---|---|
| `display interface` | All interfaces — state, speed, duplex, counters |
| `display interface GigabitEthernet 1/0/1` | Detail for a specific port |
| `display interface brief` | Summary table — all ports, link state, speed |
| `display port` | Port configuration summary |
| `display counters interface` | Traffic counters — packets, errors, drops per port |
| `display counters inbound interface GigabitEthernet 1/0/1` | Inbound counters for one port |
| `display counters outbound interface GigabitEthernet 1/0/1` | Outbound counters for one port |

**Port naming convention:**
```
GigabitEthernet 1/0/1   = Port 1  (1G copper)
GigabitEthernet 1/0/24  = Port 24 (uplink to Masergy FE0)
GigabitEthernet 1/0/25  = SFP uplink slot 1
GigabitEthernet 1/0/26  = SFP uplink slot 2
```

**Enable / disable a port (system view required):**
```bash
system-view
interface GigabitEthernet 1/0/1
  undo shutdown       # enable port
  shutdown            # disable port
quit
```

**Check a specific port status:**
```bash
display interface GigabitEthernet 1/0/21
# Port 21 = uplink to Cisco Catalyst 3750 (Switch3750-Port21)
```

---

## 4. VLAN

| Command | Description |
|---|---|
| `display vlan all` | All VLANs configured on the switch |
| `display vlan 10` | Detail for a specific VLAN |
| `display vlan brief` | Summary of all VLANs and member ports |
| `display port trunk` | All trunk ports and allowed VLANs |
| `display port hybrid` | All hybrid ports and their VLAN assignments |

**Create a VLAN:**
```bash
system-view
vlan 10
  name OFFICE_LAN
quit
```

**Assign a port to a VLAN (access port):**
```bash
system-view
interface GigabitEthernet 1/0/5
  port link-type access
  port access vlan 10
quit
```

**Configure a trunk port:**
```bash
system-view
interface GigabitEthernet 1/0/21
  port link-type trunk
  port trunk permit vlan all
  port trunk pvid vlan 1
quit
```

---

## 5. MAC Address Table

| Command | Description |
|---|---|
| `display mac-address` | Full MAC address table |
| `display mac-address GigabitEthernet 1/0/1` | MACs seen on a specific port |
| `display mac-address vlan 10` | MACs in a specific VLAN |
| `display mac-address dynamic` | Dynamically learned MAC entries only |
| `display mac-address static` | Statically configured MAC entries |
| `display mac-address count` | Total number of MAC entries |

> **Tip:** Use `display mac-address` to trace which port a device is connected to by its MAC address.

---

## 6. Spanning Tree

| Command | Description |
|---|---|
| `display stp` | STP global status and mode (STP/RSTP/MSTP) |
| `display stp brief` | Per-port STP state — Forwarding/Blocking/Discarding |
| `display stp instance 0` | Root bridge, priority, and path costs |
| `display stp interface GigabitEthernet 1/0/1` | STP detail for a specific port |

**STP port states:**
| State | Meaning |
|---|---|
| `Forwarding` | Normal — passing traffic |
| `Learning` | Building MAC table, not forwarding |
| `Blocking` | Blocking to prevent loops |
| `Discarding` | RSTP equivalent of Blocking |

---

## 7. ARP & IP

| Command | Description |
|---|---|
| `display arp` | ARP table — IP to MAC mappings |
| `display arp interface Vlan-interface 1` | ARP entries on a specific VLAN interface |
| `display ip interface brief` | All layer-3 interfaces and their IP addresses |
| `display ip routing-table` | IP routing table |

**Check switch management IP:**
```bash
display ip interface brief
# Shows the management VLAN interface IP
```

---

## 8. PoE Management

> The V1910-24G supports **802.3af (15.4W max per port)** only.
> It does **NOT** support 802.3at (PoE+).
> The Ruckus R610 runs fine on 802.3af.
> The Ruckus R650/R670 will run in reduced mode on 802.3af — use a PoE injector for full power.

| Command | Description |
|---|---|
| `display poe interface` | PoE status for all ports — power draw, state |
| `display poe interface GigabitEthernet 1/0/1` | PoE detail for a specific port |
| `display poe device` | Total PoE power budget and current consumption |

**Enable / disable PoE on a port:**
```bash
system-view
interface GigabitEthernet 1/0/1
  poe enable          # enable PoE on this port
  undo poe enable     # disable PoE on this port
quit
```

**Check which port the Ruckus AP is drawing power from:**
```bash
display poe interface
# Look for a port with power draw ~6-8W (R610 typical draw)
```

---

## 9. Link Aggregation (LACP)

| Command | Description |
|---|---|
| `display link-aggregation summary` | All LAG groups and member ports |
| `display link-aggregation verbose` | Detailed LAG status including LACP state |
| `display link-aggregation interface Bridge-Aggregation 1` | Detail for a specific LAG group |

---

## 10. SNMP

| Command | Description |
|---|---|
| `display snmp-agent` | SNMP agent status and version |
| `display snmp-agent community` | Configured SNMP community strings |
| `display snmp-agent sys-info` | SNMP system location, contact, name |
| `display snmp-agent trap-list` | Enabled SNMP traps |

---

## 11. Logging & Events

| Command | Description |
|---|---|
| `display logbuffer` | Recent log entries in the buffer |
| `display logbuffer summary` | Log buffer summary and counts |
| `display trapbuffer` | Recent SNMP trap events |
| `display info-center` | Logging configuration — syslog destinations |

---

## 12. User & Security

| Command | Description |
|---|---|
| `display local-user` | All local user accounts |
| `display ssh server status` | SSH server status |
| `display ssh server session` | Active SSH sessions |
| `display telnet server status` | Telnet server status |
| `display acl all` | All configured access control lists |
| `display port-security` | Port security configuration and violations |
| `display dhcp-snooping` | DHCP snooping status and bindings |

---

## 13. Config Management

| Command | Description |
|---|---|
| `display current-configuration` | Full running configuration |
| `display saved-configuration` | Last saved configuration |
| `save` | Save running config to flash |
| `reset saved-configuration` | Erase saved config (requires reboot to take effect) |
| `reboot` | Reboot the switch |

> ⚠️ **Always run `save` after making changes** — unsaved changes are lost on reboot.

**Save configuration:**
```bash
save
# Prompt: Are you sure? [Y/N]
Y
```

**Backup config via TFTP:**
```bash
backup startup-configuration to 192.168.1.100 HP_V1910_backup.cfg
```

---

## 14. Diagnostics

| Command | Description |
|---|---|
| `ping 8.8.8.8` | ICMP ping from the switch |
| `ping -a 192.168.1.1 8.8.8.8` | Ping with a specific source IP |
| `tracert 8.8.8.8` | Traceroute to a destination |
| `display transceiver` | SFP/fibre transceiver status and diagnostics |
| `display transceiver GigabitEthernet 1/0/25` | SFP detail for a specific uplink port |

---

## Quick Reference — Daily Health Check

```bash
display version               # firmware and uptime
display device                # hardware health
display interface brief       # all port link states
display poe device            # total PoE budget and draw
display mac-address count     # number of learned MACs
display stp brief             # STP port states
display logbuffer summary     # recent log events
```

---

## Quick Reference — Troubleshooting Checklist

```bash
# Port is down
display interface GigabitEthernet 1/0/X    # link state and errors
display stp interface GigabitEthernet 1/0/X  # STP blocking?

# Device not getting network
display mac-address GigabitEthernet 1/0/X  # is MAC learned?
display arp                                 # is IP in ARP table?
display dhcp-snooping                       # DHCP snooping issue?

# PoE device not powering on (e.g. Ruckus AP)
display poe interface GigabitEthernet 1/0/X  # power state?
display poe device                            # budget exhausted?

# Uplink to Catalyst 3750 (Port 21)
display interface GigabitEthernet 1/0/21     # link state
display port trunk                            # VLAN allowed?
display mac-address GigabitEthernet 1/0/21   # traffic flowing?

# Port 24 — Masergy external circuit
display interface GigabitEthernet 1/0/24     # link state
display counters interface GigabitEthernet 1/0/24  # errors?
```

---

## HK Office — Port Reference

| Port | Connected To | Notes |
|---|---|---|
| 1–20 | Office devices via patch panel | Standard access ports |
| 21 | Cisco Catalyst 3750 (Switch3750) | Uplink — trunk port |
| 24 | Masergy FE0 | External WAN circuit |
| 25–26 | SFP uplink slots | Available for fibre uplinks |
| Unknown | Ruckus R610 AP | PoE 802.3af — check `display poe interface` |

---

*Document maintained by: IT / Network Engineering*
*Reference: HP V1910 Switch Series Comware 5 Command Reference*
