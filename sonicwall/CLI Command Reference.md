# SonicWall NSA — CLI Command Reference

> **Device:** SonicWall NSA 3600 | **Console:** 115200 8N1 | **Last updated:** June 2026

---

## Table of Contents

1. [System Info](#1-system-info)
2. [Interfaces](#2-interfaces)
3. [Routing](#3-routing)
4. [ARP & MAC](#4-arp--mac)
5. [Connections & Sessions](#5-connections--sessions)
6. [VPN](#6-vpn)
7. [Firewall & Policies](#7-firewall--policies)
8. [DHCP](#8-dhcp)
9. [DNS & Name Resolution](#9-dns--name-resolution)
10. [Diagnostics & Ping](#10-diagnostics--ping)
11. [High Availability](#11-high-availability)
12. [Logging & Events](#12-logging--events)
13. [Security Services](#13-security-services)
14. [Bandwidth & QoS](#14-bandwidth--qos)
15. [Users & Auth](#15-users--auth)
16. [Config Management](#16-config-management)

---

## Console Access

```
Baud rate : 115200
Data bits : 8
Parity    : None
Stop bits : 1
Flow ctrl : None
```

**PuTTY (Windows):** Select `Serial` → enter COM port → set speed to `115200`

**Mac/Linux:**
```bash
screen /dev/tty.usbserial 115200
# or
minicom -s
```

---

## 1. System Info

| Command | Description |
|---|---|
| `show version` | Firmware version, model, serial number, uptime |
| `show status` | Overall system health — CPU, memory, connections |
| `show system` | Full system summary including platform and licensing |
| `show clock` | Current system date and time |
| `show license` | All active licence features and expiry dates |
| `show tech-support-report` | Full diagnostic dump — send to SonicWall TAC |

> **Tip:** Run `show version` first every time you log in to confirm the firmware and model.

---

## 2. Interfaces

| Command | Description |
|---|---|
| `show interface` | All interfaces — IP, zone, link state, speed |
| `show interface X0` | Detail for a specific interface (X0, X1, X2...) |
| `show interface all` | Extended output including secondary IPs and VLAN info |
| `show zone` | Zone definitions and interface-to-zone assignments |
| `show portshield` | PortShield groupings — which ports share a logical interface |

**Common zones:**
- `WAN` — internet-facing interfaces (X1, X2)
- `LAN` — internal network (X0)
- `DMZ` — demilitarised zone
- `MGMT` — management interface

---

## 3. Routing

| Command | Description |
|---|---|
| `show route` | IPv4 routing table — all active routes |
| `show route all` | All routes including inactive and failover paths |
| `show route ipv6` | IPv6 routing table |
| `show rip` | RIP routing protocol status and neighbours |
| `show ospf neighbor` | OSPF neighbour adjacencies and state |
| `show ospf database` | OSPF link-state database |
| `show bgp summary` | BGP peer summary and session states |

---

## 4. ARP & MAC

| Command | Description |
|---|---|
| `show arp` | ARP cache — IP to MAC mappings of connected devices |
| `show arp cache` | Alternative syntax for `show arp` |
| `show arp interface X0` | ARP entries on a specific interface only |
| `show mac-table` | MAC address table with port and VLAN mappings |

> **Tip:** Use `show arp` to confirm upstream devices are reachable.  
> Example — verify Talari T730 is seen:
> ```
> show arp
> # Look for 172.24.222.10 in the output
> ```

---

## 5. Connections & Sessions

| Command | Description |
|---|---|
| `show connections` | All active firewall sessions (can be very large) |
| `show connections count` | Total number of active sessions — quick health check |
| `show connections ip 192.168.1.10` | Sessions for a specific source/destination IP |
| `show connections proto tcp` | Filter sessions by protocol (`tcp` / `udp` / `icmp`) |
| `show connections summary` | Session counts grouped by zone pair |

---

## 6. VPN

| Command | Description |
|---|---|
| `show vpn` | All VPN tunnel status — Site-to-Site and GroupVPN |
| `show vpn sa` | Active IKE/IPsec security associations |
| `show vpn policy` | All configured VPN policies |
| `show vpn tunnel` | Per-tunnel statistics — bytes in/out, uptime |
| `show vpn phase1` | IKE Phase 1 (ISAKMP) status for all tunnels |
| `show vpn phase2` | IKE Phase 2 (IPsec) status for all tunnels |
| `show ssl-vpn` | SSL-VPN user sessions and status |

**Tunnel health indicators:**

| State | Meaning |
|---|---|
| `UP` | Tunnel is established and passing traffic |
| `CONNECTING` | Negotiation in progress |
| `DOWN` | Tunnel is not established — check Phase 1/2 |
| `IDLE` | No traffic — tunnel may time out |

---

## 7. Firewall & Policies

| Command | Description |
|---|---|
| `show access-rule` | All firewall access rules across all zone pairs |
| `show access-rule from LAN to WAN` | Rules for a specific zone pair |
| `show nat-policy` | All NAT policies (source NAT, destination NAT, 1:1 NAT) |
| `show address-object` | All address objects (hosts, ranges, groups) |
| `show service-object` | All service/port objects defined |
| `show schedule` | All time-based schedule objects |

**Zone pair syntax:**
```
show access-rule from <source-zone> to <destination-zone>

# Examples
show access-rule from LAN to WAN
show access-rule from WAN to DMZ
show access-rule from DMZ to LAN
```

---

## 8. DHCP

| Command | Description |
|---|---|
| `show dhcp server lease` | All active leases — IP, MAC, hostname, expiry |
| `show dhcp server statistics` | Pool utilisation and offer/ack counts |
| `show dhcp server binding` | Static DHCP bindings (reserved IPs) |
| `show dhcp server scope` | DHCP scope/pool configuration |

---

## 9. DNS & Name Resolution

| Command | Description |
|---|---|
| `show dns` | DNS server configuration and cache status |
| `show dns cache` | Cached DNS entries |
| `nslookup google.com` | DNS lookup from the SonicWall itself |

---

## 10. Diagnostics & Ping

| Command | Description |
|---|---|
| `ping 8.8.8.8` | Basic ICMP ping to test connectivity |
| `ping 8.8.8.8 source X0` | Ping with a specific source interface |
| `ping 8.8.8.8 count 100 size 1400` | Extended ping with count and packet size |
| `traceroute 8.8.8.8` | Trace the hop-by-hop path to a destination |
| `traceroute 8.8.8.8 source X1` | Traceroute from a specific WAN interface |

**Common diagnostic workflow:**
```bash
# Step 1 — Test local gateway reachability
ping <default-gateway-ip>

# Step 2 — Test internet reachability
ping 8.8.8.8

# Step 3 — Test DNS resolution
nslookup google.com

# Step 4 — Trace path if something is broken
traceroute 8.8.8.8
```

---

## 11. High Availability

| Command | Description |
|---|---|
| `show ha` | HA pair status — Active/Standby state, sync status |
| `show ha detail` | Detailed HA config and interface heartbeat status |
| `show ha statistics` | HA failover event history and counts |
| `show ha sync` | Configuration sync status between HA peers |

> ⚠️ **Warning:** If `show ha sync` shows out-of-sync, config changes will not survive a failover. Investigate before making further changes.

---

## 12. Logging & Events

| Command | Description |
|---|---|
| `show log` | Recent syslog entries |
| `show log category VPN` | Filter log by category (VPN / Firewall / System) |
| `show log alerts` | High-priority alert events only |
| `show event-log` | System event log — logins, config changes, reboots |
| `show syslog server` | Configured external syslog server settings |

**Log categories:**
```
VPN        Firewall      System
Network    Users         Security Services
```

---

## 13. Security Services

| Command | Description |
|---|---|
| `show content-filter` | Content filtering status and policy summary |
| `show app-control` | Application control policy and signature status |
| `show gateway-antivirus` | Gateway AV engine status and signature version |
| `show ips` | Intrusion Prevention System status and policy |
| `show anti-spyware` | Anti-spyware engine status |
| `show dpi-ssl` | Deep Packet Inspection SSL status |

> **Tip:** Check `show gateway-antivirus` and `show ips` signature dates regularly. Outdated signatures reduce protection.

---

## 14. Bandwidth & QoS

| Command | Description |
|---|---|
| `show bandwidth-management` | BWM policy status and interface queue utilisation |
| `show qos` | QoS policy summary and active classifications |
| `show interface X1 stats` | Per-interface traffic counters — bytes/packets in/out |
| `show flow-reporting` | NetFlow/IPFIX reporting status |

---

## 15. Users & Auth

| Command | Description |
|---|---|
| `show user` | All local user accounts |
| `show user active` | Currently authenticated users and their IPs |
| `show user sso` | Single Sign-On agent status and authenticated users |
| `show radius` | RADIUS server configuration and reachability |
| `show ldap` | LDAP/AD server configuration and status |

---

## 16. Config Management

| Command | Description |
|---|---|
| `show configuration` | Full running configuration dump |
| `show preferences` | Global system preferences and settings |
| `show running-config` | Current active configuration in memory |
| `show startup-config` | Last saved config — what survives a reboot |
| `write memory` | **Save running config to flash** |
| `factory-reset` | Wipe all config and return to defaults |

> ⚠️ **Always run `write memory` after making changes** — unsaved changes are lost on reboot.

> 🔴 **`factory-reset` is irreversible.** Only run via physical console with a config backup ready.

---

## Quick Reference — Daily Health Check

Run these commands at the start of each session:

```bash
show version          # confirm firmware
show status           # CPU / memory / session count
show interface        # confirm all interfaces are UP
show route            # confirm default route is present
show vpn              # confirm VPN tunnels are UP
show ha               # confirm HA sync (if applicable)
show connections count # session count sanity check
show log alerts       # any overnight alerts
```

---

## Quick Reference — Troubleshooting Checklist

```bash
# User cannot reach internet
show interface        # is WAN interface UP?
show route            # is default route present?
ping 8.8.8.8          # can SonicWall reach internet?
show connections ip <user-ip>  # is traffic hitting the firewall?
show nat-policy       # is NAT configured correctly?

# VPN tunnel is down
show vpn              # tunnel state
show vpn phase1       # Phase 1 negotiation
show vpn phase2       # Phase 2 negotiation
show log category VPN # VPN log events

# Cannot find a device
show arp              # is device in ARP table?
show dhcp server lease # did device get an IP?
show connections ip <device-ip>  # any traffic?
```

---

## HK Office — Device Reference

| Device | Model | IP | Notes |
|---|---|---|---|
| SonicWall | NSA 3600 | TBC | ASIFMA segment firewall |
| Talari SD-WAN | T730 | 172.24.222.10 | Mgmt port5 = 192.168.0.2 |
| ASA (Broadband) | Cisco ASA 5520 | 172.24.1.2 | HK-ASA-HKBROAD |
| ASA (PCCW) | Cisco ASA 5520 | 172.24.1.1 | HK-ASA-PCCW |
| Core switch | Cisco Catalyst 3750 | — | Switch3750 |
| Access switch | HP V1910-24G | — | JE006A · PoE 802.3af |
| AP | Ruckus R610 | — | Unleashed mode |

---

*Document maintained by: IT / Network Engineering*  
*Reference: SonicWall NSA Series CLI Guide — docs.sonicwall.com*
