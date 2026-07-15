iftop -i eth0 — watch a specific interface
iftop -n — skip DNS resolution (show raw IPs, faster, avoids the DNS noise you saw)
iftop -N — also skip port-name resolution
iftop -P — show port numbers (see what service the traffic is)
iftop -F 192.168.1.0/24 — filter to a specific network

For example : To view a certain interface
iam using a wireguard VPN tunnel right 

so then
iftop -i wg0