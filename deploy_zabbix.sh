#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

mkdir -p ${ZABBIX_DIR}/scripts/agentd/custix
cp -rv ${SOURCE_DIR}/custix/custix.sh            ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/scripts              ${ZABBIX_DIR}/scripts/agentd/custix/
cp -rv ${SOURCE_DIR}/custix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/custix.conf
