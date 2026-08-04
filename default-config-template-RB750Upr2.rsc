###############################################################################
# MikroTik Configuration Script
# Board: hEX PoE lite (mipsbe, switch1 chip)
# Validated command-by-command on the actual device.
# Run on a freshly reset router (factory defaults), via:
#   /import file-name=mikrotik-final-config.rsc
###############################################################################

# ====== General Settings ======
:local systemName "MikroTik"
:local adminPassword "CHANGE_ME_AFTER_PROVISIONING"

# ====== DNS Servers ======
:local dnsPrimary "8.8.8.8"
:local dnsSecondary "1.1.1.1"
:local dnsServers ($dnsPrimary . "," . $dnsSecondary)

# ====== DHCP Settings ======
:local dhcpStartIP "172.16.203.10"
:local dhcpEndIP "172.16.203.110"
:local dhcpRange ($dhcpStartIP . "-" . $dhcpEndIP)

# ====== LAN Network ======
:local lanGatewayIP "172.16.203.1"
:local lanNetwork "172.16.203.0"
:local lanCIDRBits "24"
:local lanCIDR ($lanGatewayIP . "/" . $lanCIDRBits)
:local lanNetworkCIDR ($lanNetwork . "/" . $lanCIDRBits)

# ====== Interface Names ======
:local wanInterface "ether1"
:local lanBridgeName "bridge-lan"
:local notLanBridge ("!" . $lanBridgeName)

###############################################################################
# Bridge and LAN ports
###############################################################################

:log info "Creating LAN bridge"
/interface bridge add name=$lanBridgeName

:log info "Adding LAN ports to bridge"
/interface bridge port add bridge=$lanBridgeName interface=ether2
/interface bridge port add bridge=$lanBridgeName interface=ether3
/interface bridge port add bridge=$lanBridgeName interface=ether4
/interface bridge port add bridge=$lanBridgeName interface=ether5

###############################################################################
# IP addressing, DNS, DHCP server (LAN)
###############################################################################

:log info "Setting static IP for LAN bridge"
/ip address add address=$lanCIDR interface=$lanBridgeName

:log info "Configuring DNS"
/ip dns set servers=$dnsServers allow-remote-requests=no

:log info "Creating DHCP pool"
/ip pool add name=pool-lan ranges=$dhcpRange

:log info "Creating and configuring DHCP server"
/ip dhcp-server add name=dhcp-lan address-pool=pool-lan interface=$lanBridgeName disabled=no

:log info "Adding DHCP network settings"
/ip dhcp-server network add address=$lanNetworkCIDR gateway=$lanGatewayIP dns-server=$dnsServers

###############################################################################
# WAN (DHCP client)
###############################################################################

:log info "Enabling DHCP client on WAN"
/ip dhcp-client add interface=$wanInterface disabled=no use-peer-dns=no use-peer-ntp=no add-default-route=yes

###############################################################################
# NAT
###############################################################################

:log info "Adding NAT masquerade rule"
/ip firewall nat add chain=srcnat out-interface=$wanInterface action=masquerade comment="masquerade"

###############################################################################
# Firewall - input chain
###############################################################################

:log info "Applying firewall rules (input chain)"
/ip firewall filter add chain=input action=accept connection-state=established,related,untracked comment="accept established,related,untracked"
/ip firewall filter add chain=input action=drop connection-state=invalid comment="drop invalid"
/ip firewall filter add chain=input action=accept protocol=icmp comment="accept ICMP"
/ip firewall filter add chain=input action=accept in-interface=$lanBridgeName protocol=tcp dst-port=8291,22,443 comment="allow LAN admin access (Winbox, SSH, HTTPS)"
/ip firewall filter add chain=input action=accept in-interface=$lanBridgeName protocol=tcp dst-port=53 comment="allow LAN DNS (TCP)"
/ip firewall filter add chain=input action=accept in-interface=$lanBridgeName protocol=udp dst-port=53 comment="allow LAN DNS (UDP)"
/ip firewall filter add chain=input action=drop in-interface=$notLanBridge comment="drop all not coming from LAN"

###############################################################################
# Firewall - forward chain
###############################################################################

:log info "Applying firewall rules (forward chain)"
/ip firewall filter add chain=forward action=fasttrack-connection connection-state=established,related comment="fasttrack"
/ip firewall filter add chain=forward action=accept connection-state=established,related,untracked comment="accept established,related,untracked"
/ip firewall filter add chain=forward action=drop connection-state=invalid comment="drop invalid"
/ip firewall filter add chain=forward action=drop connection-state=new connection-nat-state=!dstnat in-interface=$wanInterface comment="drop all from WAN not DSTNATed"

###############################################################################
# Discovery / MAC-server
###############################################################################

:log info "Restricting discovery and MAC-server"
/ip neighbor discovery-settings set discover-interface-list=all
/tool mac-server set allowed-interface-list=all
/tool mac-server mac-winbox set allowed-interface-list=all

###############################################################################
# System identity and admin password
###############################################################################

:log info "Setting system identity"
/system identity set name=$systemName

:log info "Setting admin password"
/user set admin password=$adminPassword

:log info "Configuration finished"
