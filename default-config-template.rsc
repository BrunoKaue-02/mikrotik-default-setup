###############################################################################
# MikroTik Default Configuration Template
# Description: Sets up LAN/WAN, DHCP, NAT, DNS and basic firewall rules
###############################################################################

# ───── General Settings ─────
:local systemName "MikroTik"
:local adminPassword "admin123"

# ───── NTP Servers (not applied in this script, defined for future use) ─────
:local ntpPrimary "173.230.149.23"
:local ntpSecondary "198.110.48.12"

# ───── DNS Servers ─────
:local dnsPrimary "8.8.8.8"
:local dnsSecondary "1.1.1.1"

# ───── DHCP Settings ─────
:local dhcpServerName "dhcp-lan"
:local dhcpPoolName "pool-lan"
:local dhcpStartIP "192.168.20.10"
:local dhcpEndIP "192.168.20.110"

# ───── LAN Network ─────
:local lanGatewayIP "192.168.20.1"
:local lanNetwork "192.168.20.0"
:local lanCIDRBits "24"
:local lanCIDR ($lanGatewayIP . "/" . $lanCIDRBits)

# ───── Interface Names ─────
:local wanInterface "ether1"
:local lanBridgeInterface "bridge"
:local lanBridgeName "bridge-lan"

# ───── NAT Exclusion ─────
:local excludedNatSubnet "192.168.1.1/24"

###############################################################################
# Start Configuration
###############################################################################

:log info "Creating LAN bridge"
/interface bridge
add name=$lanBridgeName

:log info "Adding LAN ports to bridge"
/interface bridge port
add interface=ether2 bridge=$lanBridgeName
add interface=ether3 bridge=$lanBridgeName
add interface=ether4 bridge=$lanBridgeName
add interface=ether5 bridge=$lanBridgeName

:log info "Setting static IP for LAN bridge"
/ip address add address=$lanCIDR interface=$lanBridgeInterface network=$lanNetwork

:log info "Configuring DNS"
/ip dns set servers=($dnsPrimary . "," . $dnsSecondary) allow-remote-requests=yes

:log info "Creating DHCP pool"
/ip pool add name=$dhcpPoolName ranges=($dhcpStartIP . "-" . $dhcpEndIP)

:log info "Creating and configuring DHCP server"
/ip dhcp-server add name=$dhcpServerName interface=$lanBridgeInterface address-pool=$dhcpPoolName lease-time=1d disabled=no

:log info "Adding DHCP network settings"
/ip dhcp-server network add address=($lanNetwork . "/" . $lanCIDRBits) gateway=$lanGatewayIP dns-server=($dnsPrimary . "," . $dnsSecondary)

:log info "Enabling DHCP client on WAN"
/ip dhcp-client add interface=$wanInterface disabled=no use-peer-dns=no use-peer-ntp=no add-default-route=yes

:log info "Setting system identity and admin password"
/system identity set name=$systemName
/user set admin password=$adminPassword

:log info "Adding NAT rule with exception for $excludedNatSubnet"
ip firewall nat add chain=srcnat out-interface=$etherWAN dst-address=! action=masquerade comment=""

:log info "Applying basic firewall rules"
/ip firewall filter add chain=input connection-state=established,related action=accept comment="Allow established and related connections"
/ip firewall filter add chain=input in-interface=$lanBridgeInterface protocol=tcp dst-port=8291,22,80,53 action=accept comment="Allow LAN access (Winbox, SSH, HTTP, DNS TCP)"
/ip firewall filter add chain=input in-interface=$lanBridgeInterface protocol=udp dst-port=53 action=accept comment="Allow LAN DNS (UDP)"
/ip firewall filter add chain=input protocol=icmp action=accept comment="Allow ICMP (ping)"

:log info "Configuration completed successfully"
