#!/usr/bin/env bash

source "$(dirname "$0")/ft-util/ft_util_inc_var"
source "$(dirname "$0")/ft-util/ft_util_inc_func"
source "$(dirname "$0")/ft-util/ft_util_sudoersd"

app_name="futur-tech-zabbix-apt"

# Checking which Zabbix Agent is detected and adjust include directory
$(which zabbix_agent2 >/dev/null) && zbx_conf_agent_d="/etc/zabbix/zabbix_agent2.d"
$(which zabbix_agentd >/dev/null) && zbx_conf_agent_d="/etc/zabbix/zabbix_agentd.conf.d"
if [ ! -d "${zbx_conf_agent_d}" ]; then
  $S_LOG -s crit -d $S_NAME "${zbx_conf_agent_d} Zabbix Include directory not found"
  exit 10
fi

echo "
  INSTALL NEEDED PACKAGES & FILES
------------------------------------------"

apt_conf_d="/etc/apt/apt.conf.d"
if [ -d "${apt_conf_d}" ]; then
  $S_DIR/ft-util/ft_util_file-deploy "$S_DIR/etc.zabbix/${app_name}.conf" "${zbx_conf_agent_d}/${app_name}.conf"

  # More info: https://wiki.debian.org/UnattendedUpgrades
  bak_if_exist ${apt_conf_d}/02ft-zabbix-apt
  echo '// Deployed by futur-tech-zabbix-apt
APT::Periodic::Enable "1";
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1"; 
APT::Periodic::AutocleanInterval "21";' >${apt_conf_d}/02ft-zabbix-apt
  show_bak_diff_rm ${apt_conf_d}/02ft-zabbix-apt
else
  $S_LOG -s crit -d "$S_NAME" "${apt_conf_d} is missing"
fi

echo "
  SETUP SUDOER FILES
------------------------------------------"

bak_if_exist "/etc/sudoers.d/${app_name}"
sudoersd_reset_file $app_name zabbix
sudoersd_addto_file $app_name zabbix "${S_DIR_PATH}/deploy-update.sh"
sudoersd_addto_file $app_name zabbix "/usr/bin/apt update"
show_bak_diff_rm "/etc/sudoers.d/${app_name}"

echo "
  RESTART ZABBIX LATER
------------------------------------------"

echo "systemctl restart zabbix-agent*" | at now + 1 min &>/dev/null ## restart zabbix agent with a delay
$S_LOG -s $? -d "$S_NAME" "Scheduling Zabbix Agent Restart"

$S_LOG -d "$S_NAME" "End $S_NAME"

exit
