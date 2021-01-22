#!/usr/bin/env ksh
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp

resource=${1}

OS_VENDOR=`uname -s`
if [[ ${OS_VENDOR} == 'Linux' ]]; then
    res=`lsb_release -s -d 2>/dev/null`
fi

echo ${res:-0}
exit ${rcode:-0}
