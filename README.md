# Zabbix APT Monitoring
Zabbix template to monitor Debian/Ubuntu package updates and upgrade health.

Works with Zabbix 7.0 Active Agent.

## Key checks

- Available package updates (security and non-security)
- Upgradable package list
- Held packages and autoremove candidates
- Broken/problematic `dpkg` package states
- `needrestart` kernel/services/processes status
- `reboot-required` flag
- `dpkg.log` activity (`logrt`)
- `unattended-upgrades.log` activity (`logrt`)

## Included unattended-upgrades trigger

- `Unattended-upgrades installed updates in last 1h` (INFO)
  - Expression: detects `INFO All upgrades installed` in the last hour.

## Deploy Commands

Everything is executed by only a few basic deploy scripts. 

```bash
cd /usr/local/src
git clone https://github.com/Futur-Tech/futur-tech-zabbix-apt.git
cd futur-tech-zabbix-apt

./deploy.sh 
# Main deploy script

./deploy-update.sh -b main
# This script will automatically pull the latest version of the branch ("main" in the example) and relaunch itself if a new version is found. Then it will run deploy.sh. Also note that any additional arguments given to this script will be passed to the deploy.sh script.
```

Finally import the template YAML in Zabbix Server and attach it to your host.

## Credits

Forked from https://github.com/sergiotocalini/custix
