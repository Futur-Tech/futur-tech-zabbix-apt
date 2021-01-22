#!/usr/bin/env ksh
SCRIPT_NAME=$(basename $0)
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp
SCRIPT_CACHE_TTL=10
TIMESTAMP=`date '+%s'`

. /etc/environment

resource=${1:-full}
property=${2}

refresh_cache() {
    [[ -d ${SCRIPT_CACHE} ]] || mkdir -p ${SCRIPT_CACHE}
    file=${SCRIPT_CACHE}/${SCRIPT_NAME%.*}.json
    if [[ $(( `stat -c '%Y' "${file}" 2>/dev/null`+60*${SCRIPT_CACHE_TTL} )) -le ${TIMESTAMP} ]]; then
	regex="(Not Specified|Not Present)"
	dmi=`sudo dmidecode`
	meminfo=`cat /proc/meminfo`
	cpuinfo=`lscpu`

	dmi_system=`echo "${dmi}" | sed '/^System Information/, /Handle.*/!d'`
	dmi_chassis=`echo "${dmi}" | sed '/^Chassis Information/, /Handle.*/!d'`
	dmi_moboard=`echo "${dmi}" | sed '/^Chassis Information/, /Handle.*/!d'`
	
	vendor=`echo "${dmi_system}"|grep "Manufacturer:"|awk '{print $2}'|awk '{$1=$1};1'`
	serial=`echo "${dmi_system}"|grep "Serial Number:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	model=`echo "${dmi_system}"|grep "Product Name:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`

	if [[ ${vendor} =~ (Supermicro) ]]; then
	    dmi_moboard=`echo "${dmi}" | sed '/^Base Board Information/, /Handle.*/!d'`
	    serial=`echo "${dmi_moboard}"|grep "Serial Number:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	    model=`echo "${dmi_moboard}"|grep "Product Name:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	fi
	sku=`echo "${dmi_system}"|grep "SKU Number:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	chassis_type=`echo "${dmi_chassis}"|grep "Type:"|awk -F ':' '{print $2}'|awk '{$1=$1};1'`
	if [[ ${vendor} =~ (QEMU|VMware.*|Xen|VirtualBox) ]]; then
            type='virtual'
	else
            type='physical'
	fi
	chassis[0]="${vendor}"
        chassis[1]="${model}"
        chassis[2]="${serial}"
        chassis[3]="${chassis_type}"
        for index in ${!chassis[@]}; do
            chassis[${index}]=`echo "${chassis[${index}]}" | sed -E "s:${regex}::g"`
        done
        chassis=`echo "${chassis[@]}"`
	memory=`echo "${meminfo}" | grep "^MemTotal:" | awk -F ':' '{printf "%10.0f\n", $2*1024}'` 
        memory_swap=`echo "${meminfo}" | grep "^SwapTotal:" | awk -F ':' '{printf "%10.0f\n", $2*1024}'`
	cpu_count=`echo "${cpuinfo}" | grep "^CPU(s):" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_arch=`echo "${cpuinfo}" | grep "^Architecture:" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_model=`echo "${cpuinfo}" | grep "^Model name:" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_sockets=`echo "${cpuinfo}" | grep "^Socket(s):" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_vendor=`echo "${cpuinfo}" | grep "^Vendor ID:" | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_cores_per_socket=`echo "${cpuinfo}" | grep "^Core(s) per socket:" \
				   | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	cpu_threads_per_core=`echo "${cpuinfo}" | grep "^Thread(s) per core:" \
				   | awk -F ':' '{print $2}' | awk '{$1=$1};1'`
	site=${AMANA_SITE}
	json_raw=`lsblk -d -ibo MODEL,NAME,SERIAL,SIZE,VENDOR -J 2>/dev/null | jq . 2>/dev/null`
        if [[ -z ${json_raw} ]]; then
            json_raw="{\"blockdevices\": ["
            while read line; do
		eval ${line}
                json_raw+="{"
		json_raw+="\"model\": \"${MODEL}\","
		json_raw+="\"name\": \"${NAME}\","
		json_raw+="\"serial\": null,"
		json_raw+="\"size\": \"${SIZE}\","
		json_raw+="\"vendor\": null"
		json_raw+="}"
            done < <(lsblk -d -ibo MODEL,NAME,SIZE -P 2> /dev/null)
            json_raw+="]}"
        fi
	json_keys=(
	    'chassis'
	    'cpu_arch'
	    'cpu_cores_per_socket'
	    'cpu_count'
	    'cpu_model'
	    'cpu_sockets'
	    'cpu_threads_per_core'
	    'cpu_vendor'
	    'memory'
	    'memory_swap'
	    'model'
	    'serial'
	    'sku'
	    'type'
	    'vendor'
	    'site'
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
