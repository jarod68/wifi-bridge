#!/bin/bash

# ############################################################################
# Author: 		Matthieu Holtz
# Year:   		2017
# Project: 		wifi bridge
# Description: 	        This is the wifi Managed (or client) mode script
# ############################################################################


my_dir="$(dirname "$0")"
timestamp=`date`

source "$my_dir/wifi-helpers"

echo "Use config file from $my_dir"
cp "$my_dir/wifi-bridge.config" "/tmp/wifi-bridge.config"

umount /tmp/boot-fatsys

source /tmp/wifi-bridge.config

KillProcess

WPA_SUPPLICANT_CONF="/tmp/wpa_supplicant.conf"
ICS_DHCP_CONF="/tmp/dhcpd.conf"

# Change mode to managed :

iwconfig "$WLAN_IFACE_NAME" mode managed
EchoStatus $? "Set $WLAN_IFACE_NAME to managed"

# Generate wpa_supplicant file :

wpa_passphrase $CLIENT_ESSID "$CLIENT_WPA_PASSPHRASE" > "$WPA_SUPPLICANT_CONF"
sed -i '1s/^/# Generated on '"$timestamp"'\n/' "$WPA_SUPPLICANT_CONF"
EchoStatus $? "Generate $WPA_SUPPLICANT_CONF for SSID $CLIENT_ESSID"

# Start wpa_supplicant :

wpa_supplicant -B -D wext -i "$WLAN_IFACE_NAME" -c "$WPA_SUPPLICANT_CONF"
EchoStatus $? "Start wpa_supplicant"

sleep 2

dhclient -4 "$WLAN_IFACE_NAME" &

EchoStatus $? "DHCLIENT on $WLAN_IFACE_NAME"

# Configure eth and forwarding

ifconfig "$ETH_IFACE_NAME" "$ETH_IFACE_IP" "$ETH_IFACE_SUBNET_MASTK" 

EchoStatus $? "Set IP $ETH_IFACE_IP on $ETH_IFACE_NAME"

echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

EchoStatus $? "Enable ipv4 forwarding"

iptables -t nat -A POSTROUTING -o "$WLAN_IFACE_NAME" -j MASQUERADE 

EchoStatus $? "Enable NAT masquerade"

echo "PORT_FORWARDING exists... creating rules" 	

for it in ${PORT_FORWARDING[@]}; do

        PROTOCOL=`echo "$it" | cut -d ';' -f1`
	PORT_FROM=`echo "$it" | cut -d ';' -f2`
	IP=`echo "$it" | cut -d ';' -f3`
        PORT_TO=`echo "$it" | cut -d ';' -f4`

	iptables -t nat -A PREROUTING -i "$WLAN_IFACE_NAME" -p "$PROTOCOL" --dport "$PORT_FROM" -j DNAT --to "$IP":"$PORT_TO"
	EchoStatus $? "Add PREROUTING forwarding for $PROTOCOL on input port $PORT_FROM to $IP (destination port $PORT_TO)"

done

# Configure DHCP server

echo "authoritative;" > "$ICS_DHCP_CONF"
echo "default-lease-time 600;" > "$ICS_DHCP_CONF"
echo "max-lease-time 7200;" >> "$ICS_DHCP_CONF"
echo "option subnet-mask $ETH_IFACE_SUBNET_MASTK;" >> "$ICS_DHCP_CONF"
echo "option routers $ETH_IFACE_IP;" >> "$ICS_DHCP_CONF"
echo 'option domain-name $ETH_DOMAIN_NAME;' >> "$ICS_DHCP_CONF"
echo "option domain-name-servers $ETH_DNS_SERVER;" >> "$ICS_DHCP_CONF"
echo "option ntp-servers pool.ntp.org;" >> "$ICS_DHCP_CONF"

echo "" >> "$ICS_DHCP_CONF"
echo "#DHCP reservation by MAC addresses" > "$ICS_DHCP_CONF"
echo "" >> "$ICS_DHCP_CONF"
for it in ${DHCP_RESERVATIONS[@]}; do

        MAC=`echo "$it" | cut -d ';' -f1`
	IP=`echo "$it" | cut -d ';' -f2`
	NAME=`echo "$it" | cut -d ';' -f3`

	echo "host $NAME {" >> "$ICS_DHCP_CONF"
	echo "      hardware ethernet $MAC;" >> "$ICS_DHCP_CONF"
	echo "      fixed-address $IP;" >> "$ICS_DHCP_CONF"
	echo "}" >> "$ICS_DHCP_CONF"

done
echo "" >> "$ICS_DHCP_CONF"

echo "subnet $ETH_DHCP_SUBNET netmask $ETH_IFACE_SUBNET_MASTK {" >> "$ICS_DHCP_CONF"
echo "   range $ETH_DHCP_START $ETH_DHCP_STOP;" >> "$ICS_DHCP_CONF"
echo "}" >> "$ICS_DHCP_CONF"

sed -i '1s/^/# Generated on '"$timestamp"'\n/' "$ICS_DHCP_CONF"

EchoStatus $? "Create $ICS_DHCP_CONF with content =>"

cat "$ICS_DHCP_CONF"

# Start the dhcpd server daemon :

/usr/sbin/dhcpd -cf "$ICS_DHCP_CONF" "$ETH_IFACE_NAME"
EchoStatus $? "Start dhcpcd on $ETH_IFACE_NAME"

echo "nameserver $ETH_DNS_SERVER" > /etc/resolv.conf
EchoStatus $? "Sanitize /etc/resolv.conf with only $ETH_DNS_SERVER"
