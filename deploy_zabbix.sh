#!/usr/bin/env bash
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

mkdir -p ${ZABBIX_DIR}/scripts/agentd/custix
cp -rv ${SOURCE_DIR}/custix/custix_software_updates.sh            ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/scripts              ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/custix_software_updates.conf

# Adding conf for periodic apt update (must be run with root)
OS_FAMILY=`lsb_release -s -i 2>/dev/null` 
if [[ ${OS_FAMILY} =~ (Ubuntu|Debian) ]]; then
    echo 'APT::Periodic::Enable "1";' > /etc/apt/apt.conf.d/02custix_software_updates
    echo 'APT::Periodic::Update-Package-Lists "1";' >> /etc/apt/apt.conf.d/02custix_software_updates
fi

systemctl restart zabbix-agent.service