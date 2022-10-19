#!/usr/bin/env bash
# Outputs user's information in QR code and a link ready to be used in a v2ray client (shadowlink, v2rayng, nekoray)
# Usage: script.sh partial@email ip.address SizeOfQrCode(default: 1)
# SizeOfQrCode is a number between 1-2 . If you're using a small screen like mobile (termux) use 1.

# IP address from which the qr code and the link is generated
# You can set a default IP address by changing its value to ${2:-your.ip}
# But this will prevent you from using the SizeOfQrCode arg
addr=${2}
# Configuration file
file_config=/etc/v2ray/config.json
# Name of the VPN config on user's phone/computer
name_vpn=server
# jq query to get the right inbound
jq_inbound='if .inbounds == null then .inbound[] else .inbounds[] end | select(.protocol=="vmess" or .protocol=="vless")'

c_port="$(cat "$file_config" | jq -r "$jq_inbound"'.port')"
c_host="$(cat "$file_config" | jq -r "$jq_inbound"'.streamSettings.headers.Host')"
c_path="$(cat "$file_config" | jq -r "$jq_inbound"'.streamSettings.path')"
c_net="$(cat "$file_config" | jq -r "$jq_inbound"'.streamSettings.network')"
email="$(grep -F "$1" "$file_config" | tr -d ' ,"' | sed 's/^email://')"

[[ ${#addr} == 0 ]] && exit 1
[[ "$(echo "$email" | wc -l)" != 1 ]] && { echo "no user or multiple users" ; exit 1 ;}
uuid="$(cat "$file_config" | jq -r "$jq_inbound"'.settings.clients[] | select(.email=="'"$email"'").id')"
[[ ${#uuid} == 0 ]] && exit 1
final="vmess://$(echo -n '{"add":"'$addr'","aid":"0","host":"'$c_host'","id":"'$uuid'","net":"'$c_net'","path":"'$c_path'","port":"'$c_port'","ps":"'$name_vpn'","scy":"none","sni":"","tls":"","type":"","v":"2"}' | base64 --wrap=0)"
clear
qrencode -m ${3:-1} -t utf8 <<< "$final"
echo "$final"
cat "$file_config" | jq "$jq_inbound"'.settings.clients[] | select(.email=="'"$email"'")'
echo $addr
