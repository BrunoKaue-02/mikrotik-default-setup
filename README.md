# MikroTik Configuration Template

This repository contains a reusable `.rsc` script to apply a **default configuration** to MikroTik routers, such as the RB750Gr3. It is designed for quick setup of LAN/WAN, DHCP, NAT, and firewall rules in home or small business environments.

## 📜 What the Script Does

- 🔐 Sets the **system identity** and **admin password**
- 🔧 Creates a **bridge** (`bridge-lan`) and adds ports `ether2` to `ether5`
- 🌐 Assigns a **static LAN IP** (`192.168.20.1/24`) to the bridge
- 📦 Configures **DHCP Server** with a pool (`192.168.20.10 - 192.168.20.110`)
- 🌍 Sets **custom DNS servers** (`8.8.8.8`, `1.1.1.1`)
- 🌐 Enables **DHCP client on WAN** (`ether1`) with default route
- 🔥 Adds **NAT masquerade** for all traffic except `172.16.10.0/24`
- 🛡️ Sets up **basic firewall rules**:
  - Allows **established/related connections**
  - Allows LAN access to ports `8291`, `22`, `80`, `53`
  - Allows **ICMP (ping)**

## 📁 File

- `default-config-template.rsc`: the RouterOS CLI script with all the above settings.

## 🚀 How to Use

1. Upload the file to your MikroTik device via **Winbox**, **WebFig**, or **FTP**.
2. Access the terminal and run:
   ```bash
   /import file-name=default-config-template.rsc
