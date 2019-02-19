#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
: ${CONFIG_FILE:=/usr/vpnserver/vpn_server.config}
: ${LOG_DIR:=/var/log/vpnserver}

: ${DEFAULT_HOST:=localhost}
: ${DEFAULT_HUB:=DEFAULT}

set -e

if [ ! -d "${LOG_DIR}/security_log" ]; then
  mkdir -p ${LOG_DIR}/security_log
fi

if [ ! -d "${LOG_DIR}/packet_log" ]; then
  mkdir -p ${LOG_DIR}/packet_log
fi

if [ ! -d "${LOG_DIR}/server_log" ]; then
  mkdir -p ${LOG_DIR}/server_log
  ln -s ${LOG_DIR}/*_log /usr/vpnserver/
fi

if [ ! -f "${CONFIG_FILE}" ]; then
    : ${USERNAME:=user$(cat /dev/urandom | tr -dc '0-9' | fold -w 4 | head -n 1)}
    : ${PSK:=notasecret}

    [[ ! $PASSWORD ]] && PASSWORD=$(cat /dev/urandom | tr -dc '0-9' | fold -w 20 | head -n 1 | sed 's/.\{4\}/&./g;s/.$//;')
    HPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)
    SPW=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 20 | head -n 1)

    vpnserver start 2>&1 > /dev/null

    while : ; do
        set +e
        vpncmd ${DEFAULT_HOST} /server /csv /cmd ServerCipherSet ECDHE-RSA-AES256-GCM-SHA384 2>&1 > /dev/null
        [[ $? -eq 0 ]] && break
        set -e && sleep 1
    done

    vpncmd ${DEFAULT_HOST} /server /csv /hub:${DEFAULT_HUB} /cmd SecureNatEnable
    vpncmd ${DEFAULT_HOST} /server /csv /cmd IPsecEnable /L2TP:${L2TP:-yes} /L2TPRAW:${L2TPRAW:-yes} /ETHERIP:${ETHERIP:-yes} /PSK:${PSK} /DEFAULTHUB:${DEFAULT_HUB}
    vpncmd ${DEFAULT_HOST} /server /csv /cmd OpenVpnEnable yes /PORTS:${OPENVPN_PORT:-1194}
    vpncmd ${DEFAULT_HOST} /server /csv /cmd OpenVpnMakeConfig openvpn.zip >/dev/null
    vpncmd ${DEFAULT_HOST} /server /csv /cmd SstpEnable yes
    vpncmd ${DEFAULT_HOST} /server /csv /hub:${DEFAULT_HUB} /cmd UserCreate ${USERNAME} /GROUP:none /REALNAME:none /NOTE:none
    vpncmd ${DEFAULT_HOST} /server /csv /hub:${DEFAULT_HUB} /cmd UserPasswordSet ${USERNAME} /PASSWORD:${PASSWORD}
    vpncmd ${DEFAULT_HOST} /server /csv /hub:${DEFAULT_HUB} /cmd SetHubPassword ${HPW}
    vpncmd ${DEFAULT_HOST} /server /csv /cmd ServerPasswordSet ${SPW}

    printf "# username: ${USERNAME}\n"
    printf "# password: ${PASSWORD}\n"
    printf "# hpw: ${HPW}\n"
    printf "# spw: ${SPW}\n"
    printf "# psk: ${PSK}\n\n"
    unzip -p openvpn.zip *_l3.ovpn | sed '/^#/d;s/\r//;/^$/d'

    export PASSWORD='**'
    vpnserver stop 2>&1 > /dev/null

    # while-loop to wait until server goes away
    set +e && while pgrep vpnserver > /dev/null; do sleep 1; done && set -e
fi

exec vpnserver execsvc &
tail -F /var/log/vpnserver/*_log/*.log 
exit $?
