:local systemName "MikroTik-RB750Gr3"
:local adminPassword "admin123"

:local ntpA "173.230.149.23"
:local ntpB "198.110.48.12"

:local nsA "8.8.8.8"
:local nsB "1.1.1.1"

:local dhcpServer "dhcp-lan"
:local lanPoolName "pool-lan"
:local poolStart "192.168.20.10"
:local poolEnd "192.168.20.110"

:local lanAddress "192.168.20.1"
:local lanNetworkAddress "192.168.20.0"
:local lanNetworkBits "24"
:local lanCIDR ($lanAddress . "/" . $lanNetworkBits)

:local etherWAN "ether1"
:local bridgeLAN "bridge"
:local bridgeName "bridge-lan"

:log info "Criando bridge"
/interface bridge
add name=$bridgeName

:log info "Adicionando ether2 à bridge"
/interface bridge port
add interface=ether2 bridge=$bridgeName

:log info "Adicionando ether3 à bridge"
/interface bridge port
add interface=ether3 bridge=$bridgeName

:log info "Adicionando ether4 à bridge"
/interface bridge port
add interface=ether4 bridge=$bridgeName

:log info "Adicionando ether5 à bridge"
/interface bridge port
add interface=ether5 bridge=$bridgeName

:log info "Configurando IP LAN"
/ip address remove [find interface=$bridgeLAN]
/ip address add address=$lanCIDR interface=$bridgeLAN network=$lanNetworkAddress

:log info "Configurando DNS"
/ip dns set servers=($nsA . "," . $nsB) allow-remote-requests=yes

:log info "Criando pool DHCP"
/ip pool remove [find name=$lanPoolName]
/ip pool add name=$lanPoolName ranges=($poolStart . "-" . $poolEnd)

:log info "Criando servidor DHCP"
/ip dhcp-server remove [find name=$dhcpServer]
/ip dhcp-server add name=$dhcpServer interface=$bridgeLAN address-pool=$lanPoolName lease-time=1d disabled=no
/ip dhcp-server network remove [find address=($lanNetworkAddress . "/" . $lanNetworkBits)]
/ip dhcp-server network add address=($lanNetworkAddress . "/" . $lanNetworkBits) gateway=$lanAddress dns-server=($nsA . "," . $nsB)

:log info "Configurando cliente DHCP na WAN"
/ip dhcp-client remove [find interface=$etherWAN]
/ip dhcp-client add interface=$etherWAN disabled=no use-peer-dns=no use-peer-ntp=no add-default-route=yes

:log info "Configurando identidade e senha"
/system identity set name=$systemName
/user set admin password=$adminPassword

:log info "Adicionando regra de NAT com excecao para 172.16.10.0/24"
/ip firewall nat add chain=srcnat out-interface=$etherWAN dst-address=!172.16.10.0/24 action=masquerade comment="Masquerade LAN exceto 172.16.10.0/24"

:log info "Configurando firewall basico"
/ip firewall filter add chain=input connection-state=established,related action=accept comment="Permitir conexoes estabelecidas"
/ip firewall filter add chain=input in-interface=$bridgeLAN protocol=tcp dst-port=8291,22,80,53 action=accept comment="Permitir acesso LAN"
/ip firewall filter add chain=input in-interface=$bridgeLAN protocol=udp dst-port=53 action=accept comment="Permitir DNS LAN"
/ip firewall filter add chain=input protocol=icmp action=accept comment="Permitir ICMP"

:log info "Configuracao finalizada"
