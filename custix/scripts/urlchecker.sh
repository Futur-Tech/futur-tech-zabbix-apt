#!/usr/bin/env ksh
# UserParameter=urlchecker[*],/etc/zabbix/scripts/urlchecker/urlchecker.sh -u $1 -U $2 -P $3
# UserParameter=urlchecker.version,/etc/zabbix/scripts/urlchecker/urlchecker.sh -v short
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
#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo "\nOptions:"
    echo " -P,--passwd ARG(str) Password to authenticate."
    echo " -U,--user ARG(str)   User to authenticate."
    echo " -h,--help            Displays this help message."
    echo " -r,--regex ARG(str)  Regular expression to match content."
    echo " -u,--url ARG(str)    URL to get."
    echo " -v,--version         Show the script version.\n"
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
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

checkParams() {
    if [[ -z ${URL} || ${URL} = -* ]]; then
	echo "${APP_NAME%.*}: Required arguments missing or invalid." 1>&2
	usage
    fi
}

getURL() {
    url="${1}"
    user="${2}"
    pass="${3}"
    regex="${4}"
    tmpfile=`mktemp`

    if [[ ! -z ${user} && ! -z ${pass} ]]; then
	auth="-u ${user}:${pass}"
    fi

    curl -i -k -s "${url}" ${auth} -o ${tmpfile} -w %{time_total}:
    rval=${?}

    if ! [[ -z "${regex}" ]]; then
	grep -e "${regex}" ${tmpfile}
    else
	head -1 ${tmpfile}
    fi

    rm -f ${tmpfile}
    return "${rval}"
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
	-P|--password)
	    WS_PASSWD=${ARG[$count]}
	    ;;
	-U|--user)
	    WS_USER=${ARG[$count]}
	    ;;
	-h|--help)
	    usage
	    ;;
	-r|--regex)
	    REGEX=${ARG[$count]}
	    ;;
	-u|--url)
	    URL=${ARG[$count]}
	    ;;
	-v|--version)
	    if [[ ${ARG[$count]} = "short" ]]; then
		version 1
	    else
		version 0
	    fi
	    ;;
    esac
    let "count=count+1"
done

checkParams

output=$(getURL "${URL}" "${WS_USER}" "${WS_PASSWD}" "${REGEX}")
echo ${output}
