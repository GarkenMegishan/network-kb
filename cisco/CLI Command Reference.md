# Cisco Switch — CLI Command Reference

> **Covers:** Cisco Catalyst IOS & IOS-XE Switches (3750, 3850, 9300, 2960, etc.)
> **Console:** 9600 8N1 | **Last updated:** June 2026

---

## Table of Contents

1. [Console Access](#1-console-access)
2. [CLI Modes](#2-cli-modes)
3. [System Info](#3-system-info)
4. [Interface & Port Status](#4-interface--port-status)
5. [VLAN](#5-vlan)
6. [Trunking (802.1Q)](#6-trunking-8021q)
7. [Spanning Tree (STP)](#7-spanning-tree-stp)
8. [MAC Address Table](#8-mac-address-table)
9. [ARP & Layer 3](#9-arp--layer-3)
10. [Routing (Layer 3 Switches)](#10-routing-layer-3-switches)
11. [EtherChannel / LACP](#11-etherchannel--lacp)
12. [PoE Management](#12-poe-management)
13. [CDP & LLDP](#13-cdp--lldp)
14. [SNMP](#14-snmp)
15. [SSH & Telnet](#15-ssh--telnet)
16. [ACL — Access Control Lists](#16-acl--access-control-lists)
17. [Logging & Events](#17-logging--events)
18. [Diagnostics](#18-diagnostics)
19. [Stacking (3750 / 9300)](#19-stacking-3750--9300)
20. [Config Management](#20-config-management)

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

**Default credentials (factory):**
```
Username : (none — press Enter)
Password : (none — press Enter)
Enable   : (none — press Enter)
```

> **Note:** On the Catalyst 3750 in the HK rack — if enable password is set,
> you will be prompted after typing `enable`.

---

## 2. CLI Modes

```
Switch>          User EXEC mode      — read-only, limited commands
Switch#          Privileged EXEC     — full show commands, diagnostics
Switch(config)#  Global config mode  — make configuration changes
Switch(config-if)# Interface mode    — configure a specific port
Switch(config-vlan)# VLAN mode       — configure VLANs
```

**Navigate between modes:**
```bash
Switch>  enable                  # enter privileged mode
Switch#  configure terminal      # enter global config (or: conf t)
Switch(config)# interface GigabitEthernet 1/0/1   # enter interface config
Switch(config-if)# exit          # back one level
Switch(config-if)# end           # back to privileged EXEC
Switch#  disable                 # back to user EXEC
```

---

## 3. System Info

| Command | Description |
|---|---|
| `show version` | IOS version, model, uptime, serial number, flash |
| `show inventory` | Hardware inventory — chassis, modules, SFPs |
| `show processes cpu` | CPU utilisation by process |
| `show processes cpu history` | CPU history graph (72h) |
| `show processes memory` | Memory usage by process |
| `show environment all` | Temperature, fan, power supply status |
| `show clock` | Current system date and time |
| `show boot` | Boot image and config file location |
| `show flash:` | Files in flash memory |

```bash
# Run at start of every session
show version
show environment all
show processes cpu
```

---

## 4. Interface & Port Status

| Command | Description |
|---|---|
| `show interfaces` | All interfaces — full detail, counters |
| `show interfaces status` | Summary — port, name, status, VLAN, speed/duplex |
| `show interfaces GigabitEthernet 1/0/1` | Detail for a specific port |
| `show interfaces GigabitEthernet 1/0/1 counters` | Traffic counters for one port |
| `show interfaces GigabitEthernet 1/0/1 counters errors` | Error counters only |
| `show interfaces trunk` | All trunk ports and their allowed VLANs |
| `show interfaces summary` | Brief summary of all interfaces |
| `show ip interface brief` | Layer 3 interfaces and IP addresses |

**Port naming formats:**
```
GigabitEthernet 1/0/1    = Gi1/0/1   (Catalyst 3750/3850/9300)
FastEthernet 0/1         = Fa0/1     (Catalyst 2960 older)
TenGigabitEthernet 1/1/1 = Te1/1/1   (10G uplink ports)
```

**Check a specific port quickly:**
```bash
show interfaces status | include Gi1/0/21
# Shows: port, name, status (connected/notconnect), VLAN, speed
```

**Configure a port description:**
```bash
configure terminal
interface GigabitEthernet 1/0/21
  description Uplink-to-HP-V1910-Port21
exit
```

**Shut down / bring up a port:**
```bash
configure terminal
interface GigabitEthernet 1/0/1
  shutdown        # disable port
  no shutdown     # enable port
exit
```

**Port speed and duplex:**
```bash
configure terminal
interface GigabitEthernet 1/0/1
  speed 1000
  duplex full
  no shutdown
exit
```

---

## 5. VLAN

| Command | Description |
|---|---|
| `show vlan` | All VLANs and their member ports |
| `show vlan brief` | Compact VLAN table |
| `show vlan id 10` | Detail for a specific VLAN |
| `show vlan summary` | Count of VLANs configured |
| `show interfaces vlan 10` | Layer 3 VLAN interface (SVI) status |

**Create a VLAN:**
```bash
configure terminal
vlan 10
  name OFFICE_LAN
exit
vlan 20
  name MANAGEMENT
exit
```

**Assign an access port to a VLAN:**
```bash
configure terminal
interface GigabitEthernet 1/0/5
  switchport mode access
  switchport access vlan 10
  spanning-tree portfast
  no shutdown
exit
```

**Verify VLAN assignment:**
```bash
show vlan brief
show interfaces GigabitEthernet 1/0/5 switchport
```

---

## 6. Trunking (802.1Q)

| Command | Description |
|---|---|
| `show interfaces trunk` | All trunk ports, native VLAN, allowed VLANs, active VLANs |
| `show interfaces GigabitEthernet 1/0/21 trunk` | Trunk detail for a specific port |
| `show interfaces GigabitEthernet 1/0/21 switchport` | Full switchport config including trunk |

**Configure a trunk port:**
```bash
configure terminal
interface GigabitEthernet 1/0/21
  description Uplink-to-HP-V1910
  switchport trunk encapsulation dot1q
  switchport mode trunk
  switchport trunk allowed vlan all
  switchport trunk native vlan 1
  no shutdown
exit
```

**Restrict VLANs on a trunk:**
```bash
configure terminal
interface GigabitEthernet 1/0/21
  switchport trunk allowed vlan 1,10,20,30
exit
```

**Add a VLAN to existing trunk:**
```bash
interface GigabitEthernet 1/0/21
  switchport trunk allowed vlan add 40
exit
```

---

## 7. Spanning Tree (STP)

| Command | Description |
|---|---|
| `show spanning-tree` | STP status for all VLANs |
| `show spanning-tree vlan 1` | STP for a specific VLAN — root, port states |
| `show spanning-tree vlan 1 detail` | Detailed STP info including timers |
| `show spanning-tree interface GigabitEthernet 1/0/1` | STP state for a specific port |
| `show spanning-tree summary` | STP mode and root status per VLAN |
| `show spanning-tree blockedports` | All ports in blocking state |

**STP port states:**
| State | Meaning |
|---|---|
| `FWD` | Forwarding — passing traffic normally |
| `BLK` | Blocking — preventing loop |
| `LIS` | Listening — transitioning |
| `LRN` | Learning — building MAC table |
| `DIS` | Disabled — port shutdown |

**Set STP mode:**
```bash
configure terminal
spanning-tree mode rapid-pvst    # Recommended — faster convergence
```

**Set root bridge for a VLAN:**
```bash
configure terminal
spanning-tree vlan 1 priority 4096    # Lower = more likely to be root
```

**Enable PortFast on access ports (speeds up client port convergence):**
```bash
configure terminal
interface GigabitEthernet 1/0/5
  spanning-tree portfast
exit
```

---

## 8. MAC Address Table

| Command | Description |
|---|---|
| `show mac address-table` | Full MAC address table |
| `show mac address-table dynamic` | Dynamically learned MACs only |
| `show mac address-table interface GigabitEthernet 1/0/1` | MACs on a specific port |
| `show mac address-table vlan 10` | MACs in a specific VLAN |
| `show mac address-table address aabb.ccdd.eeff` | Find which port a MAC is on |
| `show mac address-table count` | Number of MAC entries per VLAN |
| `clear mac address-table dynamic` | Clear all dynamic MAC entries |

```bash
# Trace which port a device is connected to
show mac address-table address <mac-address>
# Output shows: VLAN, MAC, Type, Port
```

---

## 9. ARP & Layer 3

| Command | Description |
|---|---|
| `show arp` | ARP table — IP to MAC mappings |
| `show ip arp` | Same as show arp |
| `show ip arp 192.168.1.10` | ARP entry for a specific IP |
| `show ip arp interface vlan 10` | ARP for a specific VLAN interface |
| `clear arp-cache` | Clear entire ARP table |
| `show ip interface brief` | All layer-3 interfaces and IPs |

---

## 10. Routing (Layer 3 Switches)

> Applies to switches with IP Services / IP Base licence and `ip routing` enabled.
> Catalyst 3750, 3850, 9300 all support layer-3 routing.

| Command | Description |
|---|---|
| `show ip route` | Full IPv4 routing table |
| `show ip route static` | Static routes only |
| `show ip route connected` | Directly connected networks |
| `show ip route summary` | Route counts by type |
| `show ip ospf neighbor` | OSPF neighbour adjacencies |
| `show ip ospf database` | OSPF link-state database |
| `show ip eigrp neighbors` | EIGRP neighbour table |
| `show ip protocols` | Routing protocols active on the switch |

**Enable IP routing (Layer 3 mode):**
```bash
configure terminal
ip routing
exit
```

**Configure a VLAN SVI (inter-VLAN routing):**
```bash
configure terminal
interface vlan 10
  ip address 192.168.10.1 255.255.255.0
  no shutdown
exit
interface vlan 20
  ip address 192.168.20.1 255.255.255.0
  no shutdown
exit
```

**Add a static default route:**
```bash
configure terminal
ip route 0.0.0.0 0.0.0.0 192.168.1.254
exit
```

---

## 11. EtherChannel / LACP

| Command | Description |
|---|---|
| `show etherchannel summary` | All EtherChannel groups — mode, member ports, state |
| `show etherchannel detail` | Detailed EtherChannel config |
| `show etherchannel port-channel` | Port-channel interface info |
| `show lacp neighbor` | LACP neighbour information |
| `show lacp internal` | LACP timers and port priority |
| `show pagp neighbor` | PAgP neighbour info (Cisco proprietary) |

**EtherChannel member states:**
| Flag | Meaning |
|---|---|
| `P` | Bundled — in port-channel |
| `D` | Down |
| `I` | Stand-alone |
| `s` | Suspended |
| `H` | Hot-standby |

**Configure LACP EtherChannel:**
```bash
configure terminal
interface range GigabitEthernet 1/0/23 - 24
  channel-group 1 mode active    # LACP active
  no shutdown
exit
interface port-channel 1
  description Uplink-Bundle
  switchport mode trunk
exit
```

---

## 12. PoE Management

> Applies to PoE-capable Catalyst models (3750-48PS, 9300, 2960-P, etc.)
> The Catalyst 3750 in the HK rack appears to be a non-PoE model — verify with `show power inline`.

| Command | Description |
|---|---|
| `show power inline` | PoE status for all ports — allocated, drawn, device |
| `show power inline GigabitEthernet 1/0/1` | PoE detail for a specific port |
| `show power inline consumption` | Total PoE budget and current draw |
| `show env power` | Power supply status and capacity |

**Enable/disable PoE on a port:**
```bash
configure terminal
interface GigabitEthernet 1/0/1
  power inline auto        # enable PoE (default)
  power inline never       # disable PoE on this port
exit
```

**Set maximum PoE per port:**
```bash
configure terminal
interface GigabitEthernet 1/0/1
  power inline auto max 15400    # limit to 15.4W (802.3af)
exit
```

---

## 13. CDP & LLDP

| Command | Description |
|---|---|
| `show cdp neighbors` | Directly connected Cisco devices |
| `show cdp neighbors detail` | Full detail — IP, model, IOS version |
| `show cdp interface` | CDP status per interface |
| `show cdp entry *` | All CDP entries with full detail |
| `show lldp neighbors` | LLDP neighbours (non-Cisco devices too) |
| `show lldp neighbors detail` | Full LLDP detail |

```bash
# Discover what is connected to which port
show cdp neighbors detail
show lldp neighbors detail
```

> **Tip:** CDP will show you connected Cisco devices (other 3750, ASA, routers).
> LLDP will show non-Cisco devices like the HP V1910 switch.

---

## 14. SNMP

| Command | Description |
|---|---|
| `show snmp` | SNMP counters and status |
| `show snmp community` | Configured community strings |
| `show snmp host` | SNMP trap destinations |
| `show snmp engineID` | SNMP v3 engine ID |
| `show snmp group` | SNMP v3 groups |
| `show snmp user` | SNMP v3 users |

---

## 15. SSH & Telnet

| Command | Description |
|---|---|
| `show ip ssh` | SSH server status, version, and timeouts |
| `show ssh` | Active SSH sessions |
| `show line vty 0 4` | VTY line configuration |
| `show users` | Currently logged-in users |
| `show tcp brief` | Active TCP connections |

**Enable SSH (requires crypto keys):**
```bash
configure terminal
hostname Switch3750
ip domain-name office.local
crypto key generate rsa modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
line vty 0 15
  transport input ssh
  login local
exit
```

---

## 16. ACL — Access Control Lists

| Command | Description |
|---|---|
| `show access-lists` | All ACLs and hit counts |
| `show access-lists ACL-NAME` | Specific ACL |
| `show ip access-lists` | IP ACLs only |
| `show ip interface GigabitEthernet 1/0/1` | Check which ACL is applied to an interface |

**Create and apply an ACL:**
```bash
configure terminal
ip access-list extended BLOCK-TELNET
  deny tcp any any eq 23 log
  permit ip any any
exit
interface GigabitEthernet 1/0/1
  ip access-group BLOCK-TELNET in
exit
```

---

## 17. Logging & Events

| Command | Description |
|---|---|
| `show logging` | Syslog buffer — recent events |
| `show logging | include ERROR` | Filter log for errors |
| `show logging | include LINK` | Filter for link up/down events |
| `show logging history` | Logging history buffer |
| `show clock` | Current time (for log correlation) |

**Enable timestamps in logs:**
```bash
configure terminal
service timestamps log datetime msec localtime
service timestamps debug datetime msec localtime
exit
```

**Send logs to syslog server:**
```bash
configure terminal
logging 192.168.1.100
logging trap informational
exit
```

---

## 18. Diagnostics

| Command | Description |
|---|---|
| `ping 8.8.8.8` | Basic ICMP ping |
| `ping 8.8.8.8 source vlan 10` | Ping from specific VLAN interface |
| `ping 8.8.8.8 repeat 100 size 1472` | Extended ping |
| `traceroute 8.8.8.8` | Hop-by-hop path trace |
| `traceroute 8.8.8.8 source vlan 10` | Traceroute from specific source |
| `show interfaces GigabitEthernet 1/0/1 counters errors` | Error counters |
| `show interfaces GigabitEthernet 1/0/1 | include error` | Filter interface output |
| `test cable-diagnostics tdr interface GigabitEthernet 1/0/1` | TDR cable test |
| `show cable-diagnostics tdr interface GigabitEthernet 1/0/1` | TDR test results |

**Common error counters to watch:**
| Counter | Indicates |
|---|---|
| `input errors` | CRC errors, bad frames — cable or duplex issue |
| `CRC` | Physical layer problem — bad cable or NIC |
| `giants` | Frames too large — MTU mismatch |
| `runts` | Frames too small — duplex mismatch |
| `output drops` | Congestion — switch buffer full |
| `collisions` | Duplex mismatch (should be 0 on full-duplex) |

---

## 19. Stacking (3750 / 9300)

| Command | Description |
|---|---|
| `show switch` | Stack members — role, MAC, priority, state |
| `show switch detail` | Detailed stack info per member |
| `show switch stack-ports` | Stack cable connections between members |
| `show switch stack-ports summary` | Stack link state and speed |
| `show platform stack-manager all` | Stack manager detail |

**Stack member roles:**
| Role | Description |
|---|---|
| `Active` | Master switch — handles control plane |
| `Standby` | Backup master — takes over if active fails |
| `Member` | Data plane only |

> **For the HK Catalyst 3750:** Run `show switch` to check if it is a single unit or stacked.

---

## 20. Config Management

| Command | Description |
|---|---|
| `show running-config` | Current running configuration |
| `show startup-config` | Saved configuration (survives reboot) |
| `show running-config interface GigabitEthernet 1/0/1` | Config for one port only |
| `copy running-config startup-config` | Save config — short form: `wr` |
| `copy running-config tftp` | Backup config to TFTP server |
| `copy tftp running-config` | Restore config from TFTP |
| `erase startup-config` | Erase saved config |
| `reload` | Reboot the switch |
| `archive config` | Archive configuration with timestamp |

> ⚠️ **Always save with `copy running-config startup-config` (or `wr`) after changes.**
> Unsaved config is lost on reboot.

**Save config:**
```bash
copy running-config startup-config
# or shorthand:
wr
```

**Backup to TFTP:**
```bash
copy running-config tftp
Address of remote host? 192.168.1.100
Destination filename? Switch3750_backup.cfg
```

**View diff — what changed since last save:**
```bash
show archive config differences nvram:startup-config system:running-config
```

---

## Quick Reference — Daily Health Check

```bash
show version                     # IOS version and uptime
show environment all             # temperature, fans, PSU
show processes cpu               # CPU utilisation
show interfaces status           # all port link states
show spanning-tree summary       # STP mode and root status
show etherchannel summary        # EtherChannel groups OK?
show power inline                # PoE budget (if PoE switch)
show logging | include ERR       # any errors overnight?
```

---

## Quick Reference — Troubleshooting Checklist

```bash
# Port is down
show interfaces GigabitEthernet 1/0/X status     # connected?
show interfaces GigabitEthernet 1/0/X            # errors?
show spanning-tree interface GigabitEthernet 1/0/X  # STP blocking?
show cdp neighbors GigabitEthernet 1/0/X detail  # what is connected?

# VLAN not working
show vlan brief                                  # VLAN exists?
show interfaces GigabitEthernet 1/0/X switchport # correct VLAN assigned?
show interfaces trunk                            # VLAN allowed on trunk?
show mac address-table vlan 10                   # MACs being learned?

# Device not reachable across switches
show mac address-table address <mac>             # which port?
show spanning-tree vlan 10 blockedports          # STP blocking a path?
show interfaces trunk                            # VLAN carried across trunk?

# Uplink to HP V1910 (Port 21 on Catalyst 3750)
show interfaces GigabitEthernet 1/0/21 status    # link UP?
show interfaces GigabitEthernet 1/0/21 trunk     # trunk active?
show interfaces GigabitEthernet 1/0/21 counters errors  # errors?
show cdp neighbors GigabitEthernet 1/0/21 detail # HP V1910 visible?

# High CPU
show processes cpu sorted                        # which process?
show processes cpu history                       # sustained or spike?
```

---

## HK Office — Catalyst 3750 Port Reference

| Port | Connected To | Config |
|---|---|---|
| 1–20 | Office devices (via patch panel) | Access ports |
| 21 | HP V1910-24G (Port 21) | Trunk uplink |
| 23–24 | SFP fibre uplinks (if used) | — |
| Unknown | ASA 5520 inside legs | Access or trunk |

**Verify with:**
```bash
show cdp neighbors detail
show interfaces status
show mac address-table
```

---

*Document maintained by: IT / Network Engineering*
*Reference: Cisco IOS / IOS-XE Command Reference — cisco.com/c/en/us/support*
