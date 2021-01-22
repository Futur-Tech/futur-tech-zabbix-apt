#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp
SCRIPT_CACHE_TTL=5
TIMESTAMP=`date '+%s'`

. /etc/environment

resource=${1:-full}
property=${2}

refresh_cache() {
    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${SCRIPT_NAME%.*}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
        IFS=":" APPS=(${AMANA_APPS})
        for app in ${APPS[@]}; do
            if [[ ${app} == 'springboot' ]]; then
		springboot=`sudo /etc/init.d/springboot list json id name desc version 2>/dev/null`
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.springboot=${springboot}" 2>/dev/null`
	    elif [[ ${app} == 'gunicorn' ]]; then
		gunicorn=`sudo /etc/init.d/gunicorn list json id name desc version 2>/dev/null`
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.gunicorn=${gunicorn}" 2>/dev/null`
	    elif [[ ${app} == 'dovecot' ]]; then
		users=`/etc/zabbix/scripts/agentd/doveix/doveix.sh -s users 2>/dev/null | wc -l`
		version=`/etc/zabbix/scripts/agentd/doveix/doveix.sh -s service -a p=version 2>/dev/null`
		dovecot="{\"version\": \"${version}\", \"users\": ${users}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.dovecot=${dovecot}" 2>/dev/null`
            elif [[ ${app} == 'mysql' ]]; then
		dbs=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s db_count 2>/dev/null`
		version=`/etc/zabbix/scripts/agentd/mysbix/mysbix.sh -s version 2>/dev/null`
		mysql="{\"version\": \"${version}\", \"databases\": ${dbs}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.mysql=${mysql}" 2>/dev/null`
            elif [[ ${app} == 'postgres' ]]; then
		dbs=`/etc/zabbix/scripts/agentd/zapgix/zapgix.sh -s db_count 2>/dev/null`
		version=`/etc/zabbix/scripts/agentd/zapgix/zapgix.sh -s version 2>/dev/null`
		postgres="{\"version\": \"${version}\", \"databases\": ${dbs}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.postgres=${postgres}" 2>/dev/null`
	    elif [[ ${app} == 'arango' ]]; then
		version=`/etc/zabbix/scripts/agentd/aranix/aranix.sh -s api-version \
						      		     -a p=version 2>/dev/null`
		license=`/etc/zabbix/scripts/agentd/aranix/aranix.sh -s api-version \
								     -a p=license 2>/dev/null`
		arango="{\"version\": \"${version}\", \"license\": \"${license}\"}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.arango=${arango}" 2>/dev/null`
	    elif [[ ${app} == 'redis' ]]; then
		dbs=`/etc/zabbix/scripts/agentd/zedisx/zedisx.sh -s info -a p=count \
								 -a p=databases 2>/dev/null`
		version=`/etc/zabbix/scripts/agentd/zedisx/zedisx.sh -s info -a p=Server \
								     -a p=redis_version 2>/dev/null`
		redis="{\"version\": \"${version/$'\r'/}\", \"databases\": ${dbs}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.redis=${redis}" 2>/dev/null`
	    elif [[ ${app} == 'elastic' ]]; then
		indices=`/etc/zabbix/scripts/agentd/elasix/elasix.sh -s discovery \
								     -a p=indices 2>/dev/null | wc -l`
		version=`/etc/zabbix/scripts/agentd/elasix/elasix.sh -s stat -a p=root \
								     -a p=version.number 2>/dev/null`
		elastic="{\"version\": \"${version/$'\r'/}\", \"indices\": ${indices}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.elastic=${elastic}" 2>/dev/null`
	    elif [[ ${app} == 'splunk' ]]; then
		version=`/etc/zabbix/scripts/agentd/spluix/spluix.sh -s service -a p=version 2>/dev/null`
		indexes=`/etc/zabbix/scripts/agentd/spluix/spluix.sh -s data -a p=indexes -a p=list 2>/dev/null| wc -l`
		splunk="{\"version\": \"${version/$'\r'/}\", \"indexes\": ${indexes}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.splunk=${splunk}" 2>/dev/null`
	    elif [[ ${app} == 'docker' ]]; then
		version=`/etc/zabbix/scripts/agentd/zocker/zocker.sh -s service -a p=version 2>/dev/null`
		containers=`/etc/zabbix/scripts/agentd/zocker/zocker.sh -s containers -a p=list 2>/dev/null| wc -l`
		docker="{\"version\": \"${version/$'\r'/}\", \"containers\": ${containers}}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.docker=${docker}" 2>/dev/null`
	    elif [[ ${app} == 'kvm' ]]; then
		kvm_report=`/etc/zabbix/scripts/agentd/virbix/virbix.sh -s report 2>/dev/null`
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.kvm=${kvm_report}" 2>/dev/null`
	    elif [[ ${app} == 'openldap' ]]; then
		version=`/etc/zabbix/scripts/agentd/zaldap/zaldap.sh -q version \
			 | grep -oE "[0-9]{1,}\.[0-9]{1,}"`
		version=`echo "${version:-0}" | paste -sd "." -`
		openldap="{\"version\": \"${version/$'\r'/}\"}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.openldap=${openldap}" 2>/dev/null`
	    elif [[ ${app} == 'logstash' ]]; then
		version=`/etc/zabbix/scripts/agentd/lostix/lostix.sh -s node_stats \
								     -a p=version 2>/dev/null`
		logstash="{\"version\": \"${version/$'\r'/}\"}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.logstash=${logstash}" 2>/dev/null`
	    elif [[ ${app} == 'jenkins' ]]; then
		version=`/etc/zabbix/scripts/agentd/jenkix/jenkix.sh -s server -a p=version 2>/dev/null`
		jenkins="{\"version\": \"${version/$'\r'/}\"}"
		json_raw=`echo "${json_raw:-{}}" | jq ".apps.jenkins=${jenkins}" 2>/dev/null`
            fi
        done
        uname_sr=`uname -sr 2>/dev/null`
	family=`echo ${uname_sr} | awk '{print $1}'`
        kernel=`echo ${uname_sr} | awk '{print $2}'`
        boottime=`cat /proc/uptime 2>/dev/null | awk '{print $1}'`
	env=${AMANA_ENV}
        if [[ ${family} == 'Linux' ]]; then
	    release=`lsb_release -sd 2>/dev/null`
            distro=`lsb_release -si 2>/dev/null`
            if [[ ${distro} =~ (Ubuntu|Debian) ]]; then
		updates_raw=`apt-get -s upgrade`
		updates_security=`echo "${updates_raw}" | grep -ci ^inst.*security | tr -d '\n'`
		updates_normal=`echo "${updates_raw}" | grep -iPc '^Inst((?!security).)*$' | tr -d '\n'`
		updates='{"normal": '${updates_normal}', "security": '${updates_security}'}'
		json_raw=`echo "${json_raw:-{}}" | jq ".updates=${updates}" 2>/dev/null`
	    fi
            filesystems='[ '
            while read line; do
		eval ${line}
		[[ -z ${MOUNTPOINT} ]] && continue
		filesystems+="{"
		filesystems+="\"name\": \"${NAME}\",\"mountpoint\": \"${MOUNTPOINT}\","
		filesystems+="\"size\": ${SIZE},\"fstype\": \"${FSTYPE}\""
		filesystems+="},"
		if [[ ${MOUNTPOINT} == '/' ]]; then
                    if ! [[ ${NAME} =~ (sda|vda|sdb)[1-9] ]]; then
			NAME="mapper/`echo "${NAME}" | sed 's/(.*).*//'`"
                    fi
                    fsroot_creation=`sudo tune2fs -l /dev/${NAME} 2>/dev/null \
		                     | grep 'Filesystem created:' \
                                     | sed 's/Filesystem created://' | awk '{$1=$1};1'`
                    installed=`date "+%s" -d "${fsroot_creation}"`
		fi
            done < <(lsblk -ibo NAME,MOUNTPOINT,SIZE,FSTYPE -P)
            filesystems="${filesystems%?} ]"
            json_raw=`echo "${json_raw:-{}}" | jq ".filesystems=${filesystems}" 2>/dev/null`

	    dtctl=`timedatectl status`
	    dst_l_oper=`echo "${dtctl}" | grep 'Last DST change:' | awk -F': ' '{print $2}'`
	    dst_l_from=`echo "${dtctl}" | grep -A 1 'Last DST change:' | tail -1 | awk '{$1=$1};1'`
	    dst_l_to=`echo "${dtctl}" | grep -A 2 'Last DST change:' | tail -1 | awk '{$1=$1};1'`
	    dst_n_oper=`echo "${dtctl}" | grep 'Next DST change:' | awk -F': ' '{print $2}'`
	    dst_n_from=`echo "${dtctl}" | grep -A 1 'Next DST change:' | tail -1 | awk '{$1=$1};1'`
	    dst_n_to=`echo "${dtctl}" | grep -A 2 'Next DST change:' | tail -1 | awk '{$1=$1};1'`

	    typeset -A content
	    content["dst_active"]="DST active:"
	    content["ntp_enable"]="(NTP enabled|Network time on):"
	    content["ntp_sync"]="NTP synchronized:"
	    content["time_local"]="Local time:"
	    content["time_universal"]="Universal time:"
	    content["time_rtc"]="RTC time:"
	    content["timezone"]="(Timezone|Time zone):"
	    content["timezone_rtc"]="RTC in local TZ:"

	    datetime='{ '
	    datetime+="\"dst_last\":{\"oper\":\"${dst_l_oper}\",\"from\":\"${dst_l_from}\",\"to\":\"${dst_l_to}\"},"
	    datetime+="\"dst_next\":{\"oper\":\"${dst_n_oper}\",\"from\":\"${dst_n_from}\",\"to\":\"${dst_n_to}\"},"
	    for idx in ${!content[@]}; do
		datetime+="\"${idx}\": \"`echo "${dtctl}" | grep -E \"${content[${idx}]}\" | awk -F': ' '{print $2}'`\","
	    done
	    datetime="${datetime%?} }"
            json_raw=`echo "${json_raw:-{}}" | jq ".datetime=${datetime}" 2>/dev/null`	    
	fi
	json_keys=(
	    'family'
	    'release'
            'boottime'
            'distro'
            'installed'
	    'env'
	)
	for key in ${json_keys[@]}; do
            eval value=\${$key}
	    json_raw=`echo "${json_raw:-{}}" | jq ".${key}=\"${value}\"" 2>/dev/null`
	done	
        echo "${json_raw}" | jq . 2>/dev/null > ${file}
    fi
    echo "${file}"
}
json=$(refresh_cache)
res=`jq -r ".${resource/full/}" ${json}`

echo "${res:-0}"
exit ${rcode:-0}
