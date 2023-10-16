# jan/02/1970 13:21:59 by RouterOS 6.49.10
# software id = IFUM-IGN7
#
# model = CCR1009-7G-1C-1S+
# serial number = 79AD06557E15

#Set dns, ntp, hostname
/ip dns
set servers=1.1.1.2,1.0.0.2
/system clock
set time-zone-name=Asia/Singapore
/system identity
set name=CCR1009
/system ntp client
set enabled=yes server-dns-names=0.pool.ntp.org,1.pool.ntp.org

#Create Bridge
/interface bridge
add name=bridge1

#Create VLANS
/interface vlan
add interface=bridge1 name=vlan10 vlan-id=10
add interface=bridge1 name=vlan20 vlan-id=20
add interface=bridge1 name=vlan30 vlan-id=30

#Set VLANS for Bridge Ports
/interface bridge port
add bridge=bridge1 interface=sfp-sfpplus1 pvid=20
add bridge=bridge1 interface=combo1 pvid=20
add bridge=bridge1 interface=ether3 pvid=20
add bridge=bridge1 interface=ether4 pvid=20
add bridge=bridge1 interface=ether5 pvid=20
add bridge=bridge1 interface=ether6 pvid=20
add bridge=bridge1 interface=ether7 pvid=10

#Set Static IP's for each VLAN
/ip address
add address=192.168.88.1/24 comment=defconf interface=combo1 network=\
    192.168.88.0
add address=192.168.88.1/24 comment=MGMT interface=ether7 network=\
    192.168.88.0
add address=192.168.10.1/24 interface=vlan10 network=192.168.10.0
add address=192.168.18.1/23 interface=vlan20 network=192.168.18.0
add address=192.168.30.1/24 interface=vlan30 network=192.168.30.0

#Configure DHCP Pools
/ip pool
add name=dhcp-pool-vlan20 ranges=192.168.18.30-192.168.55.254
add name=dhcp-pool-vlan10 ranges=192.168.10.30-192.168.10.254
add name=dhcp-pool-vlan30 ranges=192.168.30.30-192.168.30.254

#Configure DHCP
/ip dhcp-server
add address-pool=dhcp-pool-vlan20 disabled=no interface=vlan20 lease-time=1h \
    name=dhcp-vlan20
add address-pool=dhcp-pool-vlan30 disabled=no interface=vlan30 lease-time=1h \
    name=dhcp-vlan30
add address-pool=dhcp-pool-vlan10 disabled=no interface=vlan10 lease-time=8h \
    name=dhcp-vlan10

#Configure DHCP Leases
/ip dhcp-server lease
add address=192.168.18.251 comment="ESXi host" lease-time=1h mac-address=\
    11:22:33:44:55:66 server=dhcp-vlan20
add address=192.168.18.3 comment=WSUS lease-time=1h mac-address=\
    AA:BB:CC:DD:EE:FF server=dhcp-vlan20
add address=192.168.18.2 comment=WDS lease-time=1h mac-address=\
    00:11:22:33:44:55 server=dhcp-vlan20
add address=192.168.18.250 comment=DashyDashboards lease-time=1h mac-address=\
    12:34:56:78:90:AB server=dhcp-vlan20
add address=192.168.30.5 comment="Klipper (Ender 3 S1)" lease-time=1h \
    mac-address=B8:27:EB:44:B7:98 server=dhcp-vlan30
add address=192.168.30.6 comment="Octoprint (Ender 3 V2)" lease-time=1h \
    mac-address=D0:57:7B:C2:33:05 server=dhcp-vlan30
add address=192.168.10.16 comment=CCTV1 lease-time=1h mac-address=\
    10:20:30:40:50:60 server=dhcp-vlan10
add address=192.168.10.17 comment=CCTV2 lease-time=1h mac-address=\
    20:30:40:50:60:70 server=dhcp-vlan10

#Configure DHCP Networks    
/ip dhcp-server network
add address=192.168.10.0/24 dns-server=1.1.1.2,1.0.0.2 gateway=192.168.10.1
add address=192.168.18.0/24 dns-server=1.1.1.2,1.0.0.2 gateway=192.168.18.1
add address=192.168.30.0/24 dns-server=1.1.1.2,1.0.0.2 gateway=192.168.30.1

#Caps-man configuration for WIFI profiles
/caps-man configuration
add datapath.bridge=bridge1 name=cfg1
add datapath.bridge=bridge1 datapath.vlan-id=10 datapath.vlan-mode=use-tag \
    name=wifi-office security.passphrase=123qwe123qwe ssid=EngineeringGood
add datapath.bridge=bridge1 datapath.vlan-id=30 datapath.vlan-mode=use-tag \
    name=wifi-guest security.authentication-types=wpa2-psk \
    security.passphrase=123qwe123qwe ssid=EngineeringGood_Guest
add datapath.bridge=bridge1 datapath.vlan-id=20 datapath.vlan-mode=use-tag \
    name=wifi-qc security.authentication-types=wpa2-psk security.passphrase=\
    123qwe123qwe ssid=EngineeringGood_QC

#Set wireless security profile
/interface wireless security-profiles
set [ find default=yes ] supplicant-identity=MikroTik

#turn on caps manager
/caps-man manager
set enabled=yes
/caps-man manager interface
add disabled=no interface=bridge1

#Create provisioning rule for caps manager
/caps-man provisioning
add action=create-dynamic-enabled master-configuration=cfg1

#Set DHCP for both WAN ports
/ip dhcp-client
add disabled=no interface=ether1
add disabled=no interface=ether2

# Firewall Mangle Rules - Mark connections based on the incoming VLAN interface
/ip firewall mangle
add action=mark-connection chain=prerouting in-interface=vlan10 \
    new-connection-mark=vlan10_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=vlan20 \
    new-connection-mark=vlan20_conn passthrough=yes
add action=mark-connection chain=prerouting in-interface=vlan30 \
    new-connection-mark=vlan30_conn passthrough=yes
add action=mark-routing chain=prerouting connection-mark=vlan10_conn \
    in-interface=vlan10 new-routing-mark=vlan10_route
add action=mark-routing chain=prerouting connection-mark=vlan20_conn \
    in-interface=vlan20 new-routing-mark=vlan20_route
add action=mark-routing chain=prerouting connection-mark=vlan30_conn \
    in-interface=vlan30 new-routing-mark=vlan30_route

# NAT outgoing traffic for each VLAN based on the routing mark  
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1 routing-mark=\
    vlan10_route
add action=masquerade chain=srcnat out-interface=ether2 routing-mark=\
    vlan20_route
add action=masquerade chain=srcnat out-interface=ether1 routing-mark=\
    vlan30_route

 # Routing Configuration   
/ip route
add check-gateway=ping distance=1 gateway=ether1 routing-mark=vlan10_route
add check-gateway=ping distance=2 gateway=ether2 routing-mark=vlan10_route
add check-gateway=ping distance=1 gateway=ether2 routing-mark=vlan20_route
add check-gateway=ping distance=2 gateway=ether1 routing-mark=vlan20_route
add check-gateway=ping distance=1 gateway=ether1 routing-mark=vlan30_route
add check-gateway=ping distance=2 gateway=ether2 routing-mark=vlan30_route

#Firewall rules to block intervlan communication
/ip firewall filter
add action=drop chain=forward dst-address=192.168.10.0/24 src-address=\
    192.168.18.0/23
add action=drop chain=forward dst-address=192.168.10.0/24 src-address=\
    192.168.30.0/24
add action=drop chain=forward dst-address=192.168.18.0/23 src-address=\
    192.168.30.0/24
add action=drop chain=forward dst-address=192.168.30.0/24 src-address=\
    192.168.18.0/23
add action=accept chain=forward dst-address=192.168.30.1 src-address=\
    192.168.30.0/24
add action=drop chain=forward dst-address=192.168.30.0/24 src-address=\
    192.168.30.0/24

#Simple Queue to restrict traffic for vlan30
/queue simple
add max-limit=150M/150M name=limit-vlan30 target=192.168.30.0/24