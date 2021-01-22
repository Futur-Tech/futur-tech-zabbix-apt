#!/usr/bin/env ksh
SCRIPT_DIR=$(dirname $0)
SCRIPT_CACHE=${SCRIPT_DIR}/tmp

find ${1} -type f | wc -l
