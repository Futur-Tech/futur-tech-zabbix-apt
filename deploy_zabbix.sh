#!/usr/bin/env bash
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

mkdir -p ${ZABBIX_DIR}/scripts/agentd/custix
cp -rv ${SOURCE_DIR}/custix/custix_software_updates.sh            ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/scripts              ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/custix_software_updates.conf
