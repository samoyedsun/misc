modprobe af_key
docker run --name ipsec \
    -e VPN_IPSEC_PSK=AUdkZAUWzFcSoptJprtb \
    -e VPN_USER=vpnuser \
    -e VPN_PASSWORD=NRLSYb4KmM5RtkXD \
    --restart=always \
    -p 500:500/udp \
    -p 4500:4500/udp \
    -v /lib/modules:/lib/modules:ro \
    -d --privileged \
    hwdsl2/ipsec-vpn-server
