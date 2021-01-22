#!/usr/bin/env ksh
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp

resource=${1}

OS_FAMILY=`lsb_release -s -i 2>/dev/null` 
if [[ ${OS_FAMILY} =~ (Ubuntu|Debian) ]]; then
    if ! [[ -f /etc/apt/apt.conf.d/02custix ]]; then
	echo 'APT::Periodic::Enable "1";' > /etc/apt/apt.conf.d/02custix
	echo 'APT::Periodic::Update-Package-Lists "1";' >> /etc/apt/apt.conf.d/02custix
    fi
    if [[ ${resource} == "security" ]]; then
	res=`apt-get -s upgrade | grep -ci ^inst.*security | tr -d '\n'`
    elif [[ ${resource} == "updates" ]]; then
	res=`apt-get -s upgrade | grep -iPc '^Inst((?!security).)*$' | tr -d '\n'`
    fi
fi

echo ${res:-0}
exit ${rcode:-0}
