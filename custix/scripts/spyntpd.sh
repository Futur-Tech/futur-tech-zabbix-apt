#!/usr/bin/env ksh
#set -x
rval=0
# UserParameter=spyntpd[*],/etc/zabbix/scripts/spyntpd/spyntpd.sh -H localhost -q $1
# UserParameter=spyntpd.version,/etc/zabbix/scripts/spyntpd/spyntpd.sh -v short
#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="0.0.1"
APP_WEB="http://www.sergiotocalini.com.ar/"
PATH="${PATH}:/opt/csw/bin/"
GAWK=`which gawk`
NTPQ=`which ntpq`
#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    query="${1}"
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo "\nOptions:"
    echo "  -h,--help            Displays this help message."
    echo "  -q,--query ARG(str)  Query to Oracle."
    echo "  -v,--version         Show the script version.\n"
    if [[ ${query} = 1 ]]; then
	usage_query
    else
	echo "For a full list of supported queries run: ${APP_NAME%.*} -h query"
    fi
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

usage_query() {
   echo "Query's:"
   echo "  delay                 -- Delay."
   echo "  jitter                -- Jitter."
   echo "  offset                -- Offset."
   echo "  peers_count           -- Peers counts."
   echo "  stratum               -- Stratum."
}

version() {
    version="${1}"
    if [[ ${version} = 1 ]]; then
	echo "${APP_VER}"
    else
	echo "${APP_NAME%.*} ${APP_VER} ( ${APP_WEB} )"
    fi
    exit 1
}
#
#################################################################################

#################################################################################
count=0
for x in "${@}"; do
    ARG[$count]="$x"
    let "count=count+1"
done

count=1
for i in "${ARG[@]}"; do
    case "${i}" in
	-h|--help)
	    if [[ ${ARG[$count]} = "query" ]]; then
		usage 1
	    else
		usage 0
	    fi
	    ;;
	-q|--query)
	    QUERY=${ARG[$count]}
	    ;;
	-v|--version)
	    if [[ ${ARG[$count]} = "short" ]]; then
		version 1
	    else
		version 0
	    fi
	    ;;
	-H|--host)
	    HOST=${ARG[$count]}
	    ;;
    esac
    let "count=count+1"
done

case ${QUERY} in
    'delay')
	match="BEGIN {delay=0} \$1 ~ /^\*/ {delay=\$8} END {print delay}"
	;;
    'jitter')
	match="BEGIN {jitter=0} \$1 ~ /^\*/ {jitter=\$10} END {print jitter}"
	;;
    'offset')
	match="BEGIN {offset=0} \$1 ~ /^\*/ {offset=\$9} END {print offset}"
	;;
    'peers')
	match="/^\+/ {peers++} ; END {print peers}"
	;;
    'stratum')
	match="BEGIN {stratum=0} \$1 ~ /^\*/ {stratum=\$3} END {print stratum}"
	;;
esac

if [[ -n "${match}" ]]; then
    ${NTPQ} -pn "${HOST:-localhost}" | ${GAWK} "${match}"
    rval="${?}"
    if [[ "$rval" -ne 0 ]]; then
	echo "0"
    fi
else
    echo "ZBX_NOTSUPPORTED"
    rval="1"
fi

exit ${rval}
