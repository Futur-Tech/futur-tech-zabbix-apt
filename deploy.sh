#!/usr/bin/env bash

source "$(dirname "$0")/ft-util/ft_util_inc_var"

APP_NAME="futur-tech-zabbix-apt"

ZBX_CONF_AGENT_D="/etc/zabbix/zabbix_agentd.conf.d"
SRC_DIR="/usr/local/src/${APP_NAME}"

$S_LOG -d $S_NAME "Start $S_DIR_NAME/$S_NAME $*"

echo
echo "------------------------------------------"
echo "  INSTALL NEEDED PACKAGES & FILES"
echo "------------------------------------------"
echo

APT_CONF_D="/etc/apt/apt.conf.d"
if [ -d "${APT_CONF_D}" ]
then
    $S_DIR/ft-util/ft_util_file-deploy "$S_DIR/etc.zabbix/${APP_NAME}.conf" "${ZBX_CONF_AGENT_D}/${APP_NAME}.conf"

    echo 'APT::Periodic::Enable "1";' > ${APT_CONF_D}/02ft-zabbix-apt
    echo 'APT::Periodic::Update-Package-Lists "1";' >> ${APT_CONF_D}/02ft-zabbix-apt
else
    $S_LOG -s crit -d "$S_NAME" "${APT_CONF_D} is missing"
fi

echo
echo "------------------------------------------"
echo "  RESTART ZABBIX LATER"
echo "------------------------------------------"
echo

echo "service zabbix-agent restart" | at now + 1 min &>/dev/null ## restart zabbix agent with a delay
$S_LOG -s $? -d "$S_NAME" "Scheduling Zabbix Agent Restart"

$S_LOG -d "$S_NAME" "End $S_NAME"

exit