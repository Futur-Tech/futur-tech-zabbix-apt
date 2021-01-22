#!/usr/bin/env ksh
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp

. /etc/environment
IFS=":" DIRS=(${INOTIFY_DIRS})
for line in ${DIRS[*]}; do
    echo "${line}|`basename ${line}`"
done
