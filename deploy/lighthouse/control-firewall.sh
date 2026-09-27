#!/bin/sh
# Protect only this dedicated control subnet; do not alter host/mesh policy.
set -eu
chain=LIGHTHOUSE_CADDY
iptables -w -S DOCKER-USER >/dev/null
iptables -w -N "$chain" 2>/dev/null || iptables -w -S "$chain" >/dev/null
# Rebuilding this dedicated chain is safe: no unrelated chains are flushed.
iptables -w -F "$chain"
iptables -w -A "$chain" -s 172.30.250.2 -d 172.30.250.3 -p tcp --dport 2019 -j RETURN
iptables -w -A "$chain" -s 172.30.250.3 -d 172.30.250.2 -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
iptables -w -A "$chain" -d 172.30.250.0/29 -j DROP
iptables -w -A "$chain" -j RETURN
iptables -w -C DOCKER-USER -j "$chain" 2>/dev/null || iptables -w -I DOCKER-USER 1 -j "$chain"
# Cover forwarded mesh traffic too, which this host accepts before DOCKER-USER.
iptables -w -C FORWARD -d 172.30.250.0/29 -j "$chain" 2>/dev/null || iptables -w -I FORWARD 1 -d 172.30.250.0/29 -j "$chain"
# Host-network applications bypass FORWARD. Keep root's administrative recovery
# path, but reject unprivileged host processes (including UID 1003 services).
iptables -w -C OUTPUT -d 172.30.250.3 -p tcp --dport 2019 -m owner ! --uid-owner 0 -j REJECT --reject-with tcp-reset 2>/dev/null || iptables -w -I OUTPUT 1 -d 172.30.250.3 -p tcp --dport 2019 -m owner ! --uid-owner 0 -j REJECT --reject-with tcp-reset
