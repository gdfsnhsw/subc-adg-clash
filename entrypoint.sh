#!/bin/bash

set -e

if [ "$ROUTE_MODE" = "tun"]&&[ "$DNS_MODE" = "fake-ip"]; then
    /usr/lib/clash/tun.sh &
elif [ "$ROUTE_MODE" = "tproxy" ]&&[ "$DNS_MODE" = "redir_host"]; then
    /usr/lib/clash/tproxy.sh &
else
    /usr/lib/clash/redir-tun.sh &
fi

# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward


if [ ! -e '/clash_config/dashboard' ]; then
    echo "init /clash_config/dashboard"
    cp -r /root/.config/clash/dashboard /clash_config/dashboard
fi


if [ ! -e '/clash_config/config.yaml' ]; then
    echo "init /clash_config/config.yaml"
    cp  /root/.config/clash/config.yaml /clash_config/config.yaml
fi

if [ ! -e '/clash_config/Country.mmdb' ]; then
    echo "init /clash_config/Country.mmdb"
    cp  /root/.config/clash/Country.mmdb /clash_config/Country.mmdb
fi

exec "$@"
