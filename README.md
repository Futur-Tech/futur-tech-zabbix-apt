This is copy from https://github.com/sergiotocalini/custix

It removes all the items which are already available in Zabbix 5 for monitoring Linux OS.

# Custix
Custom Zabbix Scripts

# Deploy
## Zabbix

    git clone https://github.com/GuillaumeHullin/custix-software-updates
    cd custix-software-updates
    ./deploy_zabbix.sh
    systemctl restart zabbix-agent.service
    
The script is checking if there are some updates to apply.
