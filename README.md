# vank3f3/softethervpn:ubuntu16.04

Softether VPN Server for Linux
https://www.softether.org

## Usage

```

docker run -d --name=softether-vpnserver \
--net=host --privileged --name softether-vpnserver \
vank3f3/softethervpn:ubuntu16.04
```
Admin Password: softether

## Extra Options


```
wget -O /etc/vpn_server.config https://github.com/lihaixin2/docker-softether-vpnserver/raw/master/vpn_server_self.config
docker run -d --name=softether-vpnserver \
--net=host --privileged \
-v /etc/vpn_server.config:/usr/local/vpnserver/vpn_server.config \
vank3f3/softethervpn:ubuntu16.04
```
