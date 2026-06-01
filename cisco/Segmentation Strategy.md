# Cisco Switch — VLAN Segmentation Strategy with SVI

> **Scope:** Catalyst 3750 (HK Office) | **Strategy:** Isolated VLANs + Management-only inter-VLAN access
> **Last updated:** June 2026

---

## Table of Contents

1. [Design Overview](#1-design-overview)
2. [VLAN Plan](#2-vlan-plan)
3. [Security Policy](#3-security-policy)
4. [SVI Configuration](#4-svi-configuration)
5. [Inter-VLAN ACLs](#5-inter-vlan-acls)
6. [Management Server ACL](#6-management-server-acl)
7. [Access Port Configuration](#7-access-port-configuration)
8. [Trunk Port Configuration](#8-trunk-port-configuration)
9. [DHCP per VLAN](#9-dhcp-per-vlan)
10. [Verification Commands](#10-verification-commands)
11. [Full Configuration Block](#11-full-configuration-block)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Design Overview

```
                        ┌─────────────────────────────┐
                        │     Catalyst 3750 (L3)       │
                        │                             │
          ┌─────────────┤  SVI 10 — 10.10.10.1/24    │
          │             │  SVI 20 — 10.10.20.1/24    │
          │             │  SVI 30 — 10.10.30.1/24    │
          │             │  SVI 40 — 10.10.40.1/24    │
          │             │  SVI 99 — 10.10.99.1/24    │ ← Management
          │             └─────────────────────────────┘
          │                         │
          │              ACLs applied to each SVI
          │              Block all inter-VLAN traffic
          │              Permit only mgmt server (10.10.99.100)
          │
     ┌────┴─────────────────────────────────┐
     │         Traffic Rules                │
     │  VLAN 10 → VLAN 20  : DENIED        │
     │  VLAN 20 → VLAN 30  : DENIED        │
     │  VLAN 10 → WAN      : PERMITTED     │
     │  MGMT(99) → any VLAN: PERMITTED     │
     │  any VLAN → MGMT(99): DENIED        │
     └──────────────────────────────────────┘
```

**Key principles:**
- Each VLAN is a separate broadcast domain with its own SVI (gateway)
- ACLs applied **inbound on each SVI** block lateral movement between VLANs
- Only the **management server IP** (`10.10.99.100`) can reach any VLAN for monitoring
- Each VLAN can reach the internet/WAN through the upstream firewall
- Management VLAN (99) is strictly controlled — only the mgmt server lives here

---

## 2. VLAN Plan

| VLAN ID | Name | Subnet | Gateway (SVI) | Purpose |
|---|---|---|---|---|
| 10 | OFFICE_LAN | 10.10.10.0/24 | 10.10.10.1 | General office users |
| 20 | ASIFMA | 10.10.20.0/24 | 10.10.20.1 | ASIFMA segment clients |
| 30 | SERVERS | 10.10.30.0/24 | 10.10.30.1 | Internal servers |
| 40 | WIFI | 10.10.40.0/24 | 10.10.40.1 | Wireless clients (Ruckus AP) |
| 50 | VOICE | 10.10.50.0/24 | 10.10.50.1 | VoIP phones (if applicable) |
| 99 | MANAGEMENT | 10.10.99.0/24 | 10.10.99.1 | Network mgmt server only |
| 999 | BLACKHOLE | — | — | Unused ports dumped here |

**Management server:**
```
IP  : 10.10.99.100
Role: Monitoring, SNMP polling, SSH access to all devices
VLAN: 99 (MANAGEMENT)
```

---

## 3. Security Policy

| Source | Destination | Action | Reason |
|---|---|---|---|
| Any VLAN | Any other VLAN | **DENY** | Lateral movement prevention |
| Any VLAN | Internet/WAN | **PERMIT** | Normal internet access |
| MGMT server (10.10.99.100) | Any VLAN | **PERMIT** | Monitoring access |
| Any VLAN | MGMT VLAN 99 | **DENY** | Protect management plane |
| Any VLAN | VLAN 99 except mgmt server | **DENY** | No unsolicited access to mgmt |
| Established sessions | Return traffic | **PERMIT** | Stateful-like ACL (established) |

> **Note:** The Catalyst 3750 is a stateless L3 switch — ACLs are not stateful.
> Use `permit tcp any any established` to allow return TCP traffic.
> For full stateful inspection, rely on the upstream firewall (SonicWall/ASA).

---

## 4. SVI Configuration

Enable IP routing and configure one SVI per VLAN:

```bash
configure terminal

! Enable Layer 3 routing
ip routing

! ── VLAN 10 — Office LAN ──────────────────────────────
vlan 10
 name OFFICE_LAN
exit

interface vlan 10
 description Gateway-OFFICE_LAN
 ip address 10.10.10.1 255.255.255.0
 ip access-group ACL_VLAN10_IN in
 no shutdown
exit

! ── VLAN 20 — ASIFMA ──────────────────────────────────
vlan 20
 name ASIFMA
exit

interface vlan 20
 description Gateway-ASIFMA
 ip address 10.10.20.1 255.255.255.0
 ip access-group ACL_VLAN20_IN in
 no shutdown
exit

! ── VLAN 30 — Servers ─────────────────────────────────
vlan 30
 name SERVERS
exit

interface vlan 30
 description Gateway-SERVERS
 ip address 10.10.30.1 255.255.255.0
 ip access-group ACL_VLAN30_IN in
 no shutdown
exit

! ── VLAN 40 — WiFi ────────────────────────────────────
vlan 40
 name WIFI
exit

interface vlan 40
 description Gateway-WIFI
 ip address 10.10.40.1 255.255.255.0
 ip access-group ACL_VLAN40_IN in
 no shutdown
exit

! ── VLAN 50 — Voice ───────────────────────────────────
vlan 50
 name VOICE
exit

interface vlan 50
 description Gateway-VOICE
 ip address 10.10.50.1 255.255.255.0
 ip access-group ACL_VLAN50_IN in
 no shutdown
exit

! ── VLAN 99 — Management ──────────────────────────────
vlan 99
 name MANAGEMENT
exit

interface vlan 99
 description Gateway-MANAGEMENT
 ip address 10.10.99.1 255.255.255.0
 ip access-group ACL_VLAN99_IN in
 no shutdown
exit

! ── VLAN 999 — Blackhole (unused ports) ───────────────
vlan 999
 name BLACKHOLE
exit

end
```

---

## 5. Inter-VLAN ACLs

One ACL per VLAN, applied **inbound on each SVI**.
The logic for every VLAN ACL is identical:

```
1. PERMIT  — management server to reach this VLAN (return traffic)
2. DENY    — all RFC1918 private ranges (blocks all inter-VLAN)
3. PERMIT  — everything else (internet-bound traffic passes to firewall)
```

```bash
configure terminal

! ── Define management server host object ──────────────
! Used in every ACL below

! ═══════════════════════════════════════════════════════
! ACL — VLAN 10 (OFFICE_LAN)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN10_IN

 ! Allow return traffic for established TCP sessions
 permit tcp any any established

 ! Allow MGMT server to reach VLAN 10 devices
 permit ip host 10.10.99.100 10.10.10.0 0.0.0.255

 ! Allow VLAN 10 to reach its own subnet
 permit ip 10.10.10.0 0.0.0.255 10.10.10.0 0.0.0.255

 ! Block VLAN 10 from reaching any other private/internal subnet
 deny ip 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.99.0 0.0.0.255 log

 ! Permit all other traffic (internet-bound — firewall will enforce)
 permit ip any any
exit

! ═══════════════════════════════════════════════════════
! ACL — VLAN 20 (ASIFMA)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN20_IN

 permit tcp any any established

 ! Allow MGMT server to reach VLAN 20 devices
 permit ip host 10.10.99.100 10.10.20.0 0.0.0.255

 ! Allow VLAN 20 to reach its own subnet
 permit ip 10.10.20.0 0.0.0.255 10.10.20.0 0.0.0.255

 ! Block VLAN 20 from all other internal subnets
 deny ip 10.10.20.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.99.0 0.0.0.255 log

 permit ip any any
exit

! ═══════════════════════════════════════════════════════
! ACL — VLAN 30 (SERVERS)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN30_IN

 permit tcp any any established

 ! Allow MGMT server full access to servers for monitoring
 permit ip host 10.10.99.100 10.10.30.0 0.0.0.255

 ! Allow servers to reach their own subnet
 permit ip 10.10.30.0 0.0.0.255 10.10.30.0 0.0.0.255

 ! Block servers from reaching user VLANs laterally
 deny ip 10.10.30.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.99.0 0.0.0.255 log

 permit ip any any
exit

! ═══════════════════════════════════════════════════════
! ACL — VLAN 40 (WIFI)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN40_IN

 permit tcp any any established

 ! Allow MGMT server to reach WiFi subnet (for AP management)
 permit ip host 10.10.99.100 10.10.40.0 0.0.0.255

 ! Allow WiFi devices to reach their own subnet
 permit ip 10.10.40.0 0.0.0.255 10.10.40.0 0.0.0.255

 ! Block WiFi from all internal subnets (strict — guest-like)
 deny ip 10.10.40.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.99.0 0.0.0.255 log

 permit ip any any
exit

! ═══════════════════════════════════════════════════════
! ACL — VLAN 50 (VOICE)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN50_IN

 permit tcp any any established

 ! Allow MGMT server to reach voice subnet
 permit ip host 10.10.99.100 10.10.50.0 0.0.0.255

 ! Allow Voice devices to reach their own subnet
 permit ip 10.10.50.0 0.0.0.255 10.10.50.0 0.0.0.255

 ! Block Voice from all internal subnets
 deny ip 10.10.50.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.99.0 0.0.0.255 log

 permit ip any any
exit

! ═══════════════════════════════════════════════════════
! ACL — VLAN 99 (MANAGEMENT)
! ═══════════════════════════════════════════════════════
ip access-list extended ACL_VLAN99_IN

 permit tcp any any established

 ! Only permit the management server itself to send traffic out
 permit ip host 10.10.99.100 any

 ! Block everything else in the management VLAN
 deny ip any any log
exit

end
```

---

## 6. Management Server ACL

The management server at `10.10.99.100` needs to reach devices across all VLANs for:

| Protocol | Port | Purpose |
|---|---|---|
| ICMP | — | Ping / reachability monitoring |
| TCP 22 | SSH | CLI management of switches, firewalls |
| UDP 161 | SNMP | Polling metrics and interface stats |
| UDP 162 | SNMP Trap | Receive traps from devices |
| TCP 443 | HTTPS | Web UI access (SonicWall, FortiGate, Ruckus) |
| TCP 80 | HTTP | Legacy web management |
| TCP 23 | Telnet | Legacy device access (disable if possible) |
| UDP 514 | Syslog | Receive syslog from all devices |

**Restrict what management server can do per VLAN (optional fine-grained control):**

```bash
configure terminal

! Fine-grained ACL — what MGMT server can do in VLAN 10
ip access-list extended ACL_MGMT_TO_VLAN10
 permit icmp host 10.10.99.100 10.10.10.0 0.0.0.255
 permit tcp host 10.10.99.100 10.10.10.0 0.0.0.255 eq 22
 permit udp host 10.10.99.100 10.10.10.0 0.0.0.255 eq 161
 permit udp host 10.10.99.100 10.10.10.0 0.0.0.255 eq 162
 deny ip any any log
exit

end
```

> **Note:** For simplicity, the main ACL strategy in section 5 uses
> `permit ip host 10.10.99.100 <vlan-subnet>` which allows all protocols
> from the mgmt server. Use the fine-grained ACL above if you want to
> restrict to specific protocols only.

---

## 7. Access Port Configuration

Assign each physical port to its correct VLAN:

```bash
configure terminal

! ── Office LAN ports (VLAN 10) ────────────────────────
interface range GigabitEthernet 1/0/1 - 8
 description OFFICE_LAN-User-Port
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
exit

! ── ASIFMA ports (VLAN 20) ────────────────────────────
interface range GigabitEthernet 1/0/9 - 12
 description ASIFMA-User-Port
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
exit

! ── Server ports (VLAN 30) ────────────────────────────
interface range GigabitEthernet 1/0/13 - 16
 description SERVER-Port
 switchport mode access
 switchport access vlan 30
 spanning-tree portfast
 no shutdown
exit

! ── WiFi AP port (VLAN 40) ────────────────────────────
! Ruckus R610 AP — carries tagged VLAN 40 traffic
interface GigabitEthernet 1/0/17
 description Ruckus-R610-AP
 switchport mode access
 switchport access vlan 40
 spanning-tree portfast
 no shutdown
exit

! ── Voice ports (VLAN 50) ─────────────────────────────
interface range GigabitEthernet 1/0/18 - 20
 description VOICE-Phone-Port
 switchport mode access
 switchport access vlan 50
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
exit

! ── Management server port (VLAN 99) ──────────────────
interface GigabitEthernet 1/0/22
 description MGMT-Server-10.10.99.100
 switchport mode access
 switchport access vlan 99
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
exit

! ── Blackhole — all unused ports ──────────────────────
interface range GigabitEthernet 1/0/23 - 20
 description UNUSED-BLACKHOLE
 switchport mode access
 switchport access vlan 999
 shutdown
exit

end
```

---

## 8. Trunk Port Configuration

```bash
configure terminal

! ── Uplink to HP V1910-24G (Port 21) ──────────────────
interface GigabitEthernet 1/0/21
 description Uplink-to-HP-V1910-Port21
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50,99
 switchport trunk native vlan 1
 no shutdown
exit

! ── Uplink to firewall (ASA / SonicWall) ──────────────
! Adjust port number to match actual physical connection
interface GigabitEthernet 1/0/24
 description Uplink-to-Firewall
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50,99
 switchport trunk native vlan 1
 no shutdown
exit

end
```

---

## 9. DHCP per VLAN

Configure the Catalyst 3750 as DHCP server for each VLAN,
or use `ip helper-address` to forward to an external DHCP server:

### Option A — Switch as DHCP server

```bash
configure terminal

! Exclude gateway and management IPs from pools
ip dhcp excluded-address 10.10.10.1 10.10.10.20
ip dhcp excluded-address 10.10.20.1 10.10.20.20
ip dhcp excluded-address 10.10.30.1 10.10.30.20
ip dhcp excluded-address 10.10.40.1 10.10.40.20
ip dhcp excluded-address 10.10.50.1 10.10.50.20
ip dhcp excluded-address 10.10.99.1 10.10.99.20

! VLAN 10 — Office LAN
ip dhcp pool VLAN10_OFFICE
 network 10.10.10.0 255.255.255.0
 default-router 10.10.10.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name office.local
 lease 1
exit

! VLAN 20 — ASIFMA
ip dhcp pool VLAN20_ASIFMA
 network 10.10.20.0 255.255.255.0
 default-router 10.10.20.1
 dns-server 8.8.8.8 8.8.4.4
 domain-name asifma.local
 lease 1
exit

! VLAN 30 — Servers (use static IPs — no DHCP pool needed)

! VLAN 40 — WiFi
ip dhcp pool VLAN40_WIFI
 network 10.10.40.0 255.255.255.0
 default-router 10.10.40.1
 dns-server 8.8.8.8 8.8.4.4
 lease 0 8
exit

! VLAN 50 — Voice
ip dhcp pool VLAN50_VOICE
 network 10.10.50.0 255.255.255.0
 default-router 10.10.50.1
 dns-server 8.8.8.8 8.8.4.4
 lease 1
exit

! VLAN 99 — Management (static only — no DHCP)

end
```

### Option B — Forward DHCP to external server

```bash
configure terminal

! On each SVI, relay DHCP requests to external DHCP server
interface vlan 10
 ip helper-address 10.10.30.50    ! IP of your DHCP server in SERVERS VLAN
exit

interface vlan 20
 ip helper-address 10.10.30.50
exit

interface vlan 40
 ip helper-address 10.10.30.50
exit

end
```

---

## 10. Verification Commands

### Check SVIs are up

```bash
show ip interface brief | include Vlan
# All Vlan interfaces should show: up / up
```

### Check VLANs exist

```bash
show vlan brief
# All VLANs (10,20,30,40,50,99,999) should be active
```

### Check ACLs are applied

```bash
show ip interface vlan 10 | include access list
show ip interface vlan 20 | include access list
show ip interface vlan 30 | include access list
show ip interface vlan 40 | include access list
show ip interface vlan 50 | include access list
show ip interface vlan 99 | include access list
```

### Check ACL hit counters

```bash
show access-lists ACL_VLAN10_IN
show access-lists ACL_VLAN20_IN
show access-lists ACL_VLAN30_IN
show access-lists ACL_VLAN40_IN
show access-lists ACL_VLAN50_IN
show access-lists ACL_VLAN99_IN
# Deny entries should show hit counts if isolation is working
```

### Test isolation — from a device in VLAN 10, ping VLAN 20

```bash
! From a VLAN 10 client (10.10.10.x):
ping 10.10.20.x       ← should FAIL (blocked by ACL)
ping 8.8.8.8          ← should PASS (internet allowed)
ping 10.10.10.1       ← should PASS (own gateway)
```

### Test management access — from mgmt server

```bash
! From management server (10.10.99.100):
ping 10.10.10.x       ← should PASS (mgmt permitted)
ping 10.10.20.x       ← should PASS (mgmt permitted)
ping 10.10.30.x       ← should PASS (mgmt permitted)
ping 10.10.40.x       ← should PASS (mgmt permitted)
ssh admin@10.10.10.x  ← should PASS (mgmt SSH permitted)
```

### Check routing table

```bash
show ip route
# Should show connected routes for all SVIs:
# C  10.10.10.0/24 is directly connected, Vlan10
# C  10.10.20.0/24 is directly connected, Vlan20
# C  10.10.30.0/24 is directly connected, Vlan30
# etc.
```

### Check DHCP leases

```bash
show ip dhcp binding
show ip dhcp pool
show ip dhcp conflict
```

---

## 11. Full Configuration Block

Copy-paste ready — complete segmentation config for the Catalyst 3750:

```bash
configure terminal

! ── Step 1: Enable routing ────────────────────────────
ip routing

! ── Step 2: Create VLANs ─────────────────────────────
vlan 10
 name OFFICE_LAN
vlan 20
 name ASIFMA
vlan 30
 name SERVERS
vlan 40
 name WIFI
vlan 50
 name VOICE
vlan 99
 name MANAGEMENT
vlan 999
 name BLACKHOLE
exit

! ── Step 3: ACLs ──────────────────────────────────────
ip access-list extended ACL_VLAN10_IN
 permit tcp any any established
 permit ip host 10.10.99.100 10.10.10.0 0.0.0.255
 permit ip 10.10.10.0 0.0.0.255 10.10.10.0 0.0.0.255
 deny ip 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.10.0 0.0.0.255 10.10.99.0 0.0.0.255 log
 permit ip any any
exit

ip access-list extended ACL_VLAN20_IN
 permit tcp any any established
 permit ip host 10.10.99.100 10.10.20.0 0.0.0.255
 permit ip 10.10.20.0 0.0.0.255 10.10.20.0 0.0.0.255
 deny ip 10.10.20.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.20.0 0.0.0.255 10.10.99.0 0.0.0.255 log
 permit ip any any
exit

ip access-list extended ACL_VLAN30_IN
 permit tcp any any established
 permit ip host 10.10.99.100 10.10.30.0 0.0.0.255
 permit ip 10.10.30.0 0.0.0.255 10.10.30.0 0.0.0.255
 deny ip 10.10.30.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.30.0 0.0.0.255 10.10.99.0 0.0.0.255 log
 permit ip any any
exit

ip access-list extended ACL_VLAN40_IN
 permit tcp any any established
 permit ip host 10.10.99.100 10.10.40.0 0.0.0.255
 permit ip 10.10.40.0 0.0.0.255 10.10.40.0 0.0.0.255
 deny ip 10.10.40.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.50.0 0.0.0.255 log
 deny ip 10.10.40.0 0.0.0.255 10.10.99.0 0.0.0.255 log
 permit ip any any
exit

ip access-list extended ACL_VLAN50_IN
 permit tcp any any established
 permit ip host 10.10.99.100 10.10.50.0 0.0.0.255
 permit ip 10.10.50.0 0.0.0.255 10.10.50.0 0.0.0.255
 deny ip 10.10.50.0 0.0.0.255 10.10.10.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.20.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.30.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.40.0 0.0.0.255 log
 deny ip 10.10.50.0 0.0.0.255 10.10.99.0 0.0.0.255 log
 permit ip any any
exit

ip access-list extended ACL_VLAN99_IN
 permit tcp any any established
 permit ip host 10.10.99.100 any
 deny ip any any log
exit

! ── Step 4: SVIs ──────────────────────────────────────
interface vlan 10
 description Gateway-OFFICE_LAN
 ip address 10.10.10.1 255.255.255.0
 ip access-group ACL_VLAN10_IN in
 no shutdown
exit

interface vlan 20
 description Gateway-ASIFMA
 ip address 10.10.20.1 255.255.255.0
 ip access-group ACL_VLAN20_IN in
 no shutdown
exit

interface vlan 30
 description Gateway-SERVERS
 ip address 10.10.30.1 255.255.255.0
 ip access-group ACL_VLAN30_IN in
 no shutdown
exit

interface vlan 40
 description Gateway-WIFI
 ip address 10.10.40.1 255.255.255.0
 ip access-group ACL_VLAN40_IN in
 no shutdown
exit

interface vlan 50
 description Gateway-VOICE
 ip address 10.10.50.1 255.255.255.0
 ip access-group ACL_VLAN50_IN in
 no shutdown
exit

interface vlan 99
 description Gateway-MANAGEMENT
 ip address 10.10.99.1 255.255.255.0
 ip access-group ACL_VLAN99_IN in
 no shutdown
exit

! ── Step 5: DHCP Pools ────────────────────────────────
ip dhcp excluded-address 10.10.10.1 10.10.10.20
ip dhcp excluded-address 10.10.20.1 10.10.20.20
ip dhcp excluded-address 10.10.40.1 10.10.40.20
ip dhcp excluded-address 10.10.50.1 10.10.50.20
ip dhcp excluded-address 10.10.99.1 10.10.99.20

ip dhcp pool VLAN10_OFFICE
 network 10.10.10.0 255.255.255.0
 default-router 10.10.10.1
 dns-server 8.8.8.8 8.8.4.4
 lease 1
exit

ip dhcp pool VLAN20_ASIFMA
 network 10.10.20.0 255.255.255.0
 default-router 10.10.20.1
 dns-server 8.8.8.8 8.8.4.4
 lease 1
exit

ip dhcp pool VLAN40_WIFI
 network 10.10.40.0 255.255.255.0
 default-router 10.10.40.1
 dns-server 8.8.8.8 8.8.4.4
 lease 0 8
exit

ip dhcp pool VLAN50_VOICE
 network 10.10.50.0 255.255.255.0
 default-router 10.10.50.1
 dns-server 8.8.8.8 8.8.4.4
 lease 1
exit

! ── Step 6: Save ──────────────────────────────────────
end
copy running-config startup-config
```

---

## 12. Troubleshooting

| Symptom | Check | Fix |
|---|---|---|
| VLAN device has no IP | `show ip dhcp binding` | Check DHCP pool, SVI is up |
| SVI shows down/down | `show vlan brief` | VLAN must have at least one active port |
| Inter-VLAN ping works (should not) | `show access-lists` | ACL not applied to SVI — check `ip access-group` |
| MGMT server cannot reach a VLAN | `show access-lists ACL_VLANxx_IN` | Check permit rule for 10.10.99.100 |
| Internet not reachable from VLAN | `show ip route` | Default route to firewall present? |
| ACL blocking unexpected traffic | `show access-lists` | Check hit counters, review deny rules |
| VLAN not in trunk | `show interfaces trunk` | Add VLAN to trunk allowed list |

```bash
! Clear ACL counters for a clean test
clear ip access-list counters ACL_VLAN10_IN
clear ip access-list counters ACL_VLAN20_IN

! Watch ACL hits in real time
show access-lists ACL_VLAN10_IN
! Run traffic, then check again — deny counters should increment
```

---

> ⚠️ **Important reminders:**
> - The Catalyst 3750 ACLs are **stateless** — always include `permit tcp any any established` at the top of each ACL to allow return TCP traffic
> - Apply ACLs **inbound on the SVI** (`ip access-group ACL_VLANxx_IN in`) — this inspects traffic as it enters the routing engine from that VLAN
> - After adding a new VLAN, update **every other VLAN's ACL** with a deny rule for the new subnet
> - Always `copy running-config startup-config` after changes

---

*Document maintained by: IT / Network Engineering*
*Reference: Cisco IOS Security Configuration Guide — cisco.com/c/en/us/support*
