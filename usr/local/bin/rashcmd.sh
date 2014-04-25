#!/bin/bash
#####################################################################
# Remote Application SHutdown command toolkit
#
# Gerrit 'nold' Pannek - 2014
#
#####################################################################

function show_help {
	echo "RASH-Commandline-Toolkit - start/stop or wait for a remote service"
	echo "Usage: $0 [-v] <start|stop|wait-start|wait-stop> <hostname> <service>"
	exit 1
}

if [ "$1" == "-v" ] ; then
        set -x
	shift
fi

if [ -f /etc/rash/rash.conf ] ; then
	. /etc/rash/rash.conf
	if [ $RASH_ACTIVE -ne 1 ] ; then
		echo "RASH has been deactivated: /etc/rash/rash.conf"
		exit 1
	fi
else
	echo "Couldn't find /etc/rash/rash.conf - Please configure/install RASH"
	exit 1
fi

if [ $# -lt 3 ] ; then
	show_help
fi

COMMAND=$1
TARGET_HOST=$2
SERVICE=$3
THIS_HOST=$(hostname)
if [ "$COMMAND" == "start" -o "$COMMAND" == "stop" ] ; then
	if [ -f ${RASH_DIR}/${TARGET_HOST} ] ; then
		if [ "$(cut -f1 -d: ${RASH_DIR}/$TARGET_HOST)" == "${SERVICE}" ] && [ "$(cut -f3 -d: ${RASH_DIR}/$TARGET_HOST)" == "start" -o "$(cut -f3 -d: ${RASH_DIR}/$TARGET_HOST)" != "stop" ] ; then
			rm ${RASH_DIR}/${TARGET_HOST}
		fi
	fi

sudo -H -u ${RASH_USER} ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q ${RASH_USER}@${TARGET_HOST} "echo ${SERVICE}:${COMMAND} > ${RASH_DIR}/${THIS_HOST}" > /dev/null
elif [ "$COMMAND" == "wait-stop" -o "$COMMAND" == "wait-start" ] ; then
	count=0
	#Wait for answer file...
	while [ $count -le $RASH_TIMEOUT ] ; do
		IFS=$'\n'
		for file in $(ls -1 ${RASH_DIR}); do
			#Is this file from the target-host?
			if [ "$(basename $file)" == "${TARGET_HOST}" ] ; then
				#Is it the service we are waiting for?
				if [ "$(cut -f1 -d: ${RASH_DIR}/$file)" == "${SERVICE}" -a "$(cut -f2 -d: ${RASH_DIR}/$file)" != "start" -a "$(cut -f2 -d: ${RASH_DIR}/$file)" != "stop" ] ; then
					if [ "$(cut -f3 -d: ${RASH_DIR}/$file)" == "start" -a "${COMMAND}" == "wait-start" ] || \
						[ "$(cut -f3 -d: ${RASH_DIR}/$file)" == "stop" -a "${COMMAND}" == "wait-stop" ] ; then
						echo "Success: Application is ${COMMAND}'ed"		
			
						#Got good return code?
						ret=$(cut -f2 -d: ${RASH_DIR}/$file)
						rm ${RASH_DIR}/$file
						if [ $ret -ne 1 -a $ret -ne 2 ] ; then
							exit $ret
						else
							exit 3
						fi
					fi
				fi
			fi
		done	
		sleep 1
		count=$(($count + 1))
	done
	echo "TIMEOUT - Assuming App is ${COMMAND}'ed"
	exit 2
else
	show_help
fi

exit 0 
