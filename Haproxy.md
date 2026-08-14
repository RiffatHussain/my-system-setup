[root@lb1 haproxy]# cat /etc/haproxy/haproxy.cfg
global
log 127.0.0.1 local1 info
chroot /var/lib/haproxy
stats timeout 30s
user haproxy
group haproxy
daemon

defaults
log global
log-format "%ci:%cp [%tr] %ft %b/%s %TR/%Tw/%Tc/%Tr/%Ta %ST %B %CC %CS %tsc %ac/%fc/%bc/%sc/%rc %sq/%bq %hr %hs %{+Q}r"
mode http
option httplog
option redispatch
option dontlognull
timeout connect 30s
timeout client 300s
timeout server 300s

frontend http_front
bind *:443 name https
option tcplog
log global
mode tcp
acl api.backend req.ssl_sni -i lb.jimmybrings.com.au
tcp-request inspect-delay 5s
tcp-request content accept if { req_ssl_hello_type 1 }
use_backend apibackend if api.backend
default_backend http_back

frontend http_front_http
bind *:80
mode http
redirect scheme https code 301

backend http_back
mode tcp
balance roundrobin
balance leastconn
balance source
stick-table type ip size 50k expire 10m
stick on src
option ssl-hello-chk
server web2.jimmybrings 192.168.50.11:443 check
server web1.jimmybrings 192.168.50.12:443 check
backend apibackend
mode tcp
balance roundrobin
balance leastconn
balance source
stick-table type ip size 50k expire 10m
stick on src
option ssl-hello-chk
server api1.jimmybrings 192.168.50.13:443 check