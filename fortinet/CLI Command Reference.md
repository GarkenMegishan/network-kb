# FortiGate Firewall — CLI Command Reference

> **Vendor:** Fortinet | **OS:** FortiOS | **Console:** 9600 8N1 | **Last updated:** June 2026

---

## Table of Contents

1. [Console Access](#1-console-access)
2. [System Info](#2-system-info)
3. [Interfaces](#3-interfaces)
4. [Routing](#4-routing)
5. [ARP & MAC](#5-arp--mac)
6. [Firewall Policies](#6-firewall-policies)
7. [NAT](#7-nat)
8. [VPN — IPsec](#8-vpn--ipsec)
9. [VPN — SSL](#9-vpn--ssl)
10. [SD-WAN](#10-sd-wan)
11. [Security Profiles](#11-security-profiles)
12. [DHCP](#12-dhcp)
13. [DNS](#13-dns)
14. [High Availability](#14-high-availability)
15. [Users & Authentication](#15-users--authentication)
16. [Logging & Monitoring](#16-logging--monitoring)
17. [Diagnostics & Ping](#17-diagnostics--ping)
18. [Packet Capture](#18-packet-capture)
19. [Config Management](#19-config-management)
20. [FortiOS CLI Structure](#20-fortios-cli-structure)

---

## 1. Console Access

```
Baud rate : 9600
Data bits : 8
Parity    : None
Stop bits : 1
Flow ctrl : None
```

**Default credentials (factory):**
```
Username : admin
Password : (blank — press Enter)
```

**SSH access:**
```bash
ssh admin@<fortigate-ip>
```

**CLI modes:**
```bash
# Execute commands (monitoring/diagnostics)
execute ping 8.8.8.8

# Get configuration
get system interface

# Show full config
show full-configuration

# Enter config mode
config system interface
    edit port1
        set ip 192.168.1.1 255.255.255.0
    next
end
```

---

## 2. System Info

| Command | Description |
|---|---|
| `get system status` | Firmware version, serial, hostname, uptime |
| `get system performance status` | CPU, memory, sessions — live snapshot |
| `get system performance top` | Running processes by CPU usage |
| `diagnose hardware sysinfo memory` | Detailed memory usage |
| `diagnose hardware sysinfo cpu` | CPU core utilisation |
| `get system ha status` | HA cluster state and sync status |
| `execute date` | Current system date and time |
| `execute time` | Current system time |
| `get system global` | Global settings — hostname, timezone, admin timeout |
| `get system fortiguard` | FortiGuard licence and service status |

```bash
# Quick health check — run at start of every session
get system status
get system performance status
get system ha status
```

---

## 3. Interfaces

| Command | Description |
|---|---|
| `get system interface` | All interfaces — IP, status, speed, zone |
| `get system interface physical` | Physical interfaces only |
| `diagnose ip address list` | All IP addresses on all interfaces |
| `diagnose netlink interface list` | Interface stats — bytes, packets, errors |
| `fnsysctl ifconfig` | Low-level interface stats (like Linux ifconfig) |

**Show a specific interface:**
```bash
show system interface port1
```

**Check interface up/down status:**
```bash
diagnose netlink interface list
# Look for: flag=... state UP or DOWN
```

**Configure an interface:**
```bash
config system interface
    edit wan1
        set mode static
        set ip 203.0.113.1 255.255.255.0
        set allowaccess ping https ssh
        set role wan
    next
end
```

**Common interface roles:**
| Role | Description |
|---|---|
| `wan` | WAN / internet-facing |
| `lan` | Internal LAN |
| `dmz` | DMZ segment |
| `undefined` | Unassigned |

---

## 4. Routing

| Command | Description |
|---|---|
| `get router info routing-table all` | Full routing table — all routes |
| `get router info routing-table static` | Static routes only |
| `get router info routing-table connected` | Directly connected routes |
| `get router info routing-table database` | Full RIB including inactive routes |
| `get router info ospf neighbor` | OSPF neighbours |
| `get router info ospf database` | OSPF LSDB |
| `get router info bgp summary` | BGP peer summary |
| `get router info bgp neighbors` | BGP neighbour detail |
| `diagnose ip rtcache list` | Route cache (fast-path routes) |

**Add a static route:**
```bash
config router static
    edit 0
        set dst 10.0.0.0 255.0.0.0
        set gateway 192.168.1.254
        set device port1
    next
end
```

---

## 5. ARP & MAC

| Command | Description |
|---|---|
| `get system arp` | ARP table — IP to MAC mappings |
| `diagnose ip arp list` | Detailed ARP table with interface |
| `diagnose ip arp delete <ip>` | Remove a specific ARP entry |
| `execute mactable list` | MAC address table (switch mode) |

```bash
# Find a device by IP
diagnose ip arp list | grep 192.168.1.10
```

---

## 6. Firewall Policies

| Command | Description |
|---|---|
| `show firewall policy` | All firewall policies |
| `show firewall policy <id>` | Specific policy by ID number |
| `get firewall policy` | All policies with hit counters |
| `diagnose firewall iprope list` | Internal policy table |
| `diagnose firewall iprope show 100004` | Policy lookup table detail |

**Check policy hit counts:**
```bash
get firewall policy
# Shows: policyid, name, srcintf, dstintf, action, packets, bytes
```

**Add a firewall policy:**
```bash
config firewall policy
    edit 0
        set name "LAN-to-WAN"
        set srcintf "port2"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
        set logtraffic all
    next
end
```

**Policy actions:**
| Action | Meaning |
|---|---|
| `accept` | Allow traffic |
| `deny` | Block traffic (silent drop) |
| `ipsec` | Route to IPsec VPN tunnel |

---

## 7. NAT

| Command | Description |
|---|---|
| `show firewall ippool` | IP pools for source NAT |
| `show firewall vip` | Virtual IPs (destination NAT / port forward) |
| `show firewall vipgrp` | VIP groups |
| `diagnose firewall fqdn list` | FQDN address objects resolved IPs |

**Configure a VIP (port forward):**
```bash
config firewall vip
    edit "RDP-Server"
        set extip 203.0.113.1
        set extintf wan1
        set portforward enable
        set extport 3389
        set mappedip 192.168.1.100
        set mappedport 3389
    next
end
```

---

## 8. VPN — IPsec

| Command | Description |
|---|---|
| `get vpn ipsec tunnel summary` | All IPsec tunnels — UP/DOWN status |
| `get vpn ipsec tunnel details` | Detailed tunnel stats — bytes, packets |
| `diagnose vpn tunnel list` | Low-level tunnel info |
| `diagnose vpn ike gateway list` | IKE gateway (Phase 1) status |
| `diagnose vpn ike errors` | IKE negotiation errors |
| `diagnose vpn ike log-filter dst-addr4 <ip>` | Filter IKE logs by peer IP |
| `execute vpn ipsec restart` | Restart all IPsec tunnels |

**Bring a tunnel up/down:**
```bash
diagnose vpn tunnel up <tunnel-name>
diagnose vpn tunnel down <tunnel-name>
```

**Full IPsec debug:**
```bash
diagnose debug reset
diagnose debug application ike -1
diagnose debug enable
# Reproduce issue
diagnose debug disable
diagnose debug reset
```

---

## 9. VPN — SSL

| Command | Description |
|---|---|
| `get vpn ssl monitor` | Active SSL-VPN user sessions |
| `get vpn ssl settings` | SSL-VPN server configuration |
| `diagnose vpn ssl list` | Detailed SSL-VPN session list |
| `diagnose vpn ssl statistics` | SSL-VPN connection statistics |

**Disconnect an SSL-VPN user:**
```bash
execute vpn sslvpn del-tunnel <index>
```

---

## 10. SD-WAN

| Command | Description |
|---|---|
| `get system sdwan` | SD-WAN configuration summary |
| `diagnose sys sdwan member` | SD-WAN member interfaces and status |
| `diagnose sys sdwan health-check` | Health check status per WAN member |
| `diagnose sys sdwan service` | SD-WAN rules/services and matched traffic |
| `diagnose sys sdwan route` | SD-WAN route decisions |
| `diagnose netlink interface list` | Bandwidth utilisation per WAN interface |

```bash
# Check which WAN link is active and healthy
diagnose sys sdwan health-check

# Check SD-WAN traffic distribution
diagnose sys sdwan service
```

**SD-WAN health check states:**
| State | Meaning |
|---|---|
| `alive` | Link is healthy, passing health checks |
| `dead` | Link failed health checks — in failover |
| `unknown` | Health check not yet determined |

---

## 11. Security Profiles

| Command | Description |
|---|---|
| `show antivirus profile` | AV profile configuration |
| `show webfilter profile` | Web filter profile configuration |
| `show ips sensor` | IPS sensor configuration |
| `show application list` | Application control lists |
| `show dnsfilter profile` | DNS filter profiles |
| `show ssl-ssh-profile` | SSL deep inspection profiles |
| `get system fortiguard` | FortiGuard service status and update times |
| `execute update-now` | Force FortiGuard signature update |

**Check IPS signature version:**
```bash
diagnose autoupdate versions
# Shows: AV engine, IPS engine, FortiGuard DB versions and dates
```

---

## 12. DHCP

| Command | Description |
|---|---|
| `get dhcp server` | All DHCP server configurations |
| `diagnose ip dhcp list` | All active DHCP leases |
| `diagnose ip dhcp server-list` | DHCP server status |
| `execute dhcp lease-list` | DHCP lease table |
| `execute dhcp lease-clear all` | Clear all DHCP leases |

```bash
# Find a device's IP by hostname
diagnose ip dhcp list | grep <hostname>
```

---

## 13. DNS

| Command | Description |
|---|---|
| `get system dns` | DNS server configuration |
| `diagnose ip dns list` | DNS cache entries |
| `diagnose ip dns flush` | Flush DNS cache |
| `execute nslookup <domain>` | DNS lookup from FortiGate |
| `execute ping <domain>` | Ping using domain name |

---

## 14. High Availability

| Command | Description |
|---|---|
| `get system ha status` | HA cluster role, sync state, uptime |
| `diagnose sys ha status` | Detailed HA status and failover history |
| `diagnose sys ha checksum show` | Config checksum — must match across cluster |
| `diagnose sys ha checksum recalculate` | Force checksum recalculation |
| `get system ha` | HA configuration — mode, priority, interfaces |
| `execute ha synchronize start` | Force config sync to standby |

**HA roles:**
| Role | Description |
|---|---|
| `Primary` | Active unit — handling traffic |
| `Secondary` | Standby unit — ready for failover |

> ⚠️ **If checksums do not match**, config sync has failed. Run `execute ha synchronize start` and recheck.

---

## 15. Users & Authentication

| Command | Description |
|---|---|
| `show user local` | Local user accounts |
| `show user group` | User groups |
| `show user radius` | RADIUS server configuration |
| `show user ldap` | LDAP/AD server configuration |
| `diagnose test authserver ldap <server> <user> <pass>` | Test LDAP authentication |
| `diagnose test authserver radius <server> <user> <pass>` | Test RADIUS authentication |
| `get user fsso` | Fortinet SSO (FSSO) agent status |
| `diagnose debug fsso list` | FSSO authenticated users |

---

## 16. Logging & Monitoring

| Command | Description |
|---|---|
| `execute log display` | Display recent logs |
| `execute log filter reset` | Reset log filters |
| `execute log filter category 1` | Filter by category (1=traffic, 4=event, 5=virus) |
| `execute log filter device 0` | Filter by device (0=memory, 1=disk) |
| `diagnose log test` | Send a test log entry to verify logging |
| `get log syslogd setting` | Syslog server configuration |
| `get log fortianalyzer setting` | FortiAnalyzer connection settings |

**Log categories:**
| Number | Category |
|---|---|
| 0 | Traffic |
| 1 | Event |
| 2 | Virus |
| 3 | Web filter |
| 4 | IPS |
| 5 | Email filter |
| 6 | Application control |

**View traffic logs for a specific IP:**
```bash
execute log filter reset
execute log filter field srcip 192.168.1.10
execute log filter category 0
execute log display
```

---

## 17. Diagnostics & Ping

| Command | Description |
|---|---|
| `execute ping 8.8.8.8` | Basic ICMP ping |
| `execute ping-options source <ip>` | Set source IP for ping |
| `execute ping-options interface <port>` | Set source interface for ping |
| `execute traceroute 8.8.8.8` | Traceroute |
| `diagnose sniffer packet any 'host 8.8.8.8' 4` | Live packet capture |
| `diagnose netstat list` | Active connections |
| `diagnose sys session list` | All active firewall sessions |
| `diagnose sys session filter dst 8.8.8.8` | Filter sessions by destination |
| `diagnose sys session stat` | Session table statistics |

**Ping with source interface:**
```bash
execute ping-options source 192.168.1.1
execute ping-options repeat-count 10
execute ping 8.8.8.8
```

**Check session count:**
```bash
diagnose sys session stat
# Look for: session_count
```

---

## 18. Packet Capture

**Quick capture — live output:**
```bash
diagnose sniffer packet <interface> '<filter>' <verbosity> <count>

# Examples:
diagnose sniffer packet wan1 'host 8.8.8.8' 4
diagnose sniffer packet any 'port 443' 4 100
diagnose sniffer packet port2 'src host 192.168.1.10' 4

# Stop capture:
Ctrl+C
```

**Verbosity levels:**
| Level | Output |
|---|---|
| 1 | Header only |
| 2 | Header + data |
| 3 | Header + data + interface |
| 4 | Header + data + interface + timestamp |
| 6 | Full hex dump |

**Debug flow — trace a packet through policy:**
```bash
diagnose debug reset
diagnose debug flow filter addr 192.168.1.10
diagnose debug flow filter daddr 8.8.8.8
diagnose debug flow show function-name enable
diagnose debug flow show iprope enable
diagnose debug flow trace start 100
diagnose debug enable
# Reproduce the issue
diagnose debug disable
diagnose debug reset
```

---

## 19. Config Management

| Command | Description |
|---|---|
| `show full-configuration` | Complete running configuration |
| `show` | Configuration delta from defaults only |
| `get system checksum status` | Config integrity checksum |
| `execute backup config ftp <ip> <path>` | Backup config to FTP server |
| `execute backup config tftp <filename> <ip>` | Backup config to TFTP server |
| `execute restore config tftp <filename> <ip>` | Restore config from TFTP |
| `execute factoryreset` | Full factory reset |
| `execute reboot` | Reboot the FortiGate |

> ⚠️ **`execute factoryreset`** wipes all configuration. Only run via console with backup ready.

**Backup config to TFTP:**
```bash
execute backup config tftp FortiGate_backup.conf 192.168.1.100
```

**View recent admin changes:**
```bash
execute log filter category 1
execute log filter field action admin
execute log display
```

---

## 20. FortiOS CLI Structure

```
get        — read current values (no config tree)
show       — display configuration (config tree format)
config     — enter configuration mode
diagnose   — low-level diagnostics and debug
execute    — run one-time actions (ping, backup, reboot)
```

**Config mode pattern:**
```bash
config <table>
    edit <entry>
        set <attribute> <value>
        unset <attribute>
    next
    delete <entry>
end
```

**Example — edit then verify:**
```bash
config system interface
    edit port1
        set description "LAN Interface"
    next
end

# Verify
show system interface port1
```

---

## Quick Reference — Daily Health Check

```bash
get system status                    # firmware, uptime, serial
get system performance status        # CPU, memory, sessions
get system ha status                 # HA sync OK?
get system interface                 # all interfaces UP?
get router info routing-table all    # default route present?
get vpn ipsec tunnel summary         # VPN tunnels UP?
diagnose sys sdwan health-check      # SD-WAN WAN links healthy?
execute log filter category 1
execute log display                  # recent events
```

---

## Quick Reference — Troubleshooting Checklist

```bash
# User cannot reach internet
get system interface                 # WAN interface UP?
get router info routing-table all    # default route?
execute ping 8.8.8.8                 # FortiGate can reach internet?
diagnose sys session filter dst 8.8.8.8
diagnose sys session list            # is traffic hitting FW?
get firewall policy                  # policy hit count increasing?

# VPN tunnel down
get vpn ipsec tunnel summary         # tunnel state
diagnose vpn ike gateway list        # Phase 1 up?
diagnose vpn ike errors              # negotiation errors?
diagnose debug application ike -1    # full IKE debug

# Packet not passing policy
diagnose debug flow filter addr <src-ip>
diagnose debug flow trace start 100
diagnose debug enable                # trace packet decision

# High CPU/memory
get system performance status        # current utilisation
get system performance top           # which process?
diagnose sys session stat            # session count normal?

# SD-WAN link failover
diagnose sys sdwan health-check      # which link is dead?
diagnose sys sdwan member            # member status
get router info routing-table all    # route changed?
```

---

*Document maintained by: IT / Network Engineering*
*Reference: Fortinet FortiOS CLI Reference — docs.fortinet.com*
