#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp/${SCRIPT_NAME%.*}
SCRIPT_CACHE_TTL=0
TIMESTAMP=`date '+%s'`

DISK_SCRIPT="${SCRIPT_DIR}/hw-info.sh blockdevices"
DISK_EXCLUDE=""

method=${1}
resource=${2}
property=${3}

zabbix_not_support() {
    echo "ZBX_NOTSUPPORTED"
    exit 1
}

refresh_cache() {
    resource=${1}

    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${resource}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	hdrs[1]="read_ops"
	hdrs[2]="read_merges"
	hdrs[3]="read_sectors"
	hdrs[4]="read_ticks"
	hdrs[5]="write_ops"
	hdrs[6]="write_merges"
	hdrs[7]="write_sectors"
	hdrs[8]="write_ticks"
	hdrs[9]="in_flight"
	hdrs[10]="io_ticks"
	hdrs[11]="time_in_queue"

	json_raw="{ \"name\": \"${resource}\", \"stats\": { "

	data=`cat /sys/block/${resource}/stat 2>/dev/null`
	for idx in ${!hdrs[@]}; do
	    key="${hdrs[${idx}]}"
	    val=`echo "${data}" | awk -v col=${idx} '{print $col}'`
	    json_raw+="\"${key}\":\"${val}\","
        done

	json_raw="${json_raw%?}}}"
        echo "${json_raw}" | jq . 2>/dev/null > ${file}
    fi
    echo "${file}"
}

if [[ ${method:-list} =~ (list|LIST|all|ALL) ]]; then
    res=`${DISK_SCRIPT} | jq -r ".[] | [.name, .size] | join(\"|\")" 2>/dev/null`
elif [[ ${method} == "stats" ]]; then
    disk_json=$(refresh_cache ${resource})
    [ ${?} != 0 ] && zabbix_not_support

    if ! [[ ${property} =~ (^[[:blank:]]*$|full|all) ]]; then
        attr="stats.${property}"
    else
	attr="stats"
    fi
    res=`jq -r ".${attr/full/}" ${disk_json} 2>/dev/null`
fi

echo "${res}"
exit ${rcode:-0}
