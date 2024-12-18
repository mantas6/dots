# router-setup

Linux router/server etc

`/etc/NetworkManager/conf.d/unmanaged.conf`
```
[keyfile]
unmanaged-devices=interface-name:wlan0
```

set ip address of wlan0 to be in range of dhcp-range config dnsmasq

```
ip link set up dev wlan0
ip addr add 192.168.0.50/24 dev wlan0
```

## NAT setup

`/etc/sysctl.d/30-ipforward-local.conf`
```
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
net.ipv6.conf.all.forwarding = 1
```

## Firewalld forwarding

```
firewall-cmd --zone=external --change-interface=net0 --permanent
firewall-cmd --zone=internal --change-interface=wlan0 --permanent
```

```
firewall-cmd --permanent --new-policy int2ext
firewall-cmd --permanent --policy int2ext --add-ingress-zone internal
firewall-cmd --permanent --policy int2ext --add-egress-zone external
firewall-cmd --permanent --policy int2ext --set-target ACCEPT
firewall-cmd --reload
```

dns does not work withiut these

```
firewall-cmd --zone=internal --permanent --add-service dns
firewall-cmd --zone=internal --permanent --add-service dhcp
firewall-cmd --zone=internal --permanent --add-service dhcpv6
```

network manager was intefereing with net0 which is android tether so i had to set connection.zone to external

```
sudo nmcli device modify net0 connection.zone external
```

also i had to set a persistent interface name with udevs

`/etc/udev/rules.d/10-network.rules`
```
SUBSYSTEM=="net", ACTION=="add", ATTRS{idVendor}=="12ab", ATTRS{idProduct}=="3cd4", NAME="net0”
```

## Misc

add ip for unamanged inteface

`/etc/systemd/system/assign-wlan0-ip.service`
```
[Unit]
Description=Create virtual wireless interface
Requires=sys-subsystem-net-devices-wlan0.device
After=network.target
After=sys-subsystem-net-devices-wlan0.device
[Service]
Type=oneshot
ExecStart=/usr/bin/ip dev addr add 192.168.0.50/24 dev wlan0
[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/hostapd.service.d/override.conf`
```
[Unit]
BindsTo=sys-subsystem-net-devices-wlan0.device
After=sys-subsystem-net-devices-wlan0.device
```

### Dnsmasq config
`/etc/dnsmasq.d/00-base.conf`
```
interface=eth0

# Enable local network domains
local=/lan/
domain=lan

# Automatic domain names
expand-hosts

# Interface address
# NOTE: address must be in DHCP range
listen-address=::1,127.0.0.1,192.168.0.1

dhcp-range=192.168.0.1,192.168.0.255,12h

# DNS
# Increase cache size
cache-size=10000
```

## Wifi bridge setup


```
sudo nmcli connection add con-name wifibridge type ethernet ifname eth0 ipv4.method shared ipv6.method ignore
sudo nmcli con up wifibridge
```
