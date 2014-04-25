#!/bin/bash
#####################################################################
# Remote Application SHutdown Watchdog
#
# Gerrit 'nold' Pannek 2014
#
#####################################################################

function show_help {
        echo "RASH-Watchdog - Watching for incomming commands to start/stop a daemon"
        echo "Usage: $0 [-h] [-v]"
        exit 1
}

if [ "$1" == "-v" ] ; then
	set -x
fi

if [ ! -f /etc/rash/rash.conf ] ; then
        echo "Couldn't find /etc/rash/rash.conf - Please install/configure RASH"
        exit 1
fi

. /etc/rash/rash.conf
if [ ! -f /etc/rash/services.allowed -o $(wc -l /etc/rash/services.allowed | awk '{print $1}') -lt 1 ] ; then
        echo "Please add all allowed services to /etc/rash/services.allowed"
        exit 1
fi

set -x

if [ "$1" == "-h" -o "$1" == "--help" ] ; then
        show_help
fi


##Main

THIS_HOST=$(hostname)
while true ; do
        # Gucken ob jemand etwas von uns will
        OLD_IFS=$IFS
        IFS=$'\n'
        for file in $(ls -1 ${RASH_DIR}); do
                #echo "Found file: $file"
                target_host=$(basename ${RASH_DIR}/$file)
                command=$(cut -f2 -d: ${RASH_DIR}/$file)
                service=$(cut -f1 -d: ${RASH_DIR}/$file)

		if [ "$command" != "start" -a "$command" != "stop" ] ; then
			continue
		fi

		##################################################################
		# Check if the requested Service is allowed
		service_allowed=0
		for serv in $(cat /etc/rash/services.allowed) ; do
			if [ "$serv" == "$service" ] ; then
				service_allowed=1
				break
			fi
		done
		
		if [ $service_allowed -eq 0 ] ; then
			logger -t RASH "Service '$service' is not in /etc/rash/service.allowed"
			rm ${RASH_DIR}/$file
			continue
		fi

		##################################################################
		


                /etc/init.d/$service $command
                ret=$?
		logger -t RASH "Application ${service} ${command} on ${THIS_HOST} from ${target_host}" 
		sudo -u rashuser ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q ${RASH_USER}@${target_host} "echo ${service}:${ret}:${command} > ${RASH_DIR}/${THIS_HOST}"
                rm ${RASH_DIR}/$file
        done

        # Check if all Services are reachable
        if [ $WATCHDOG_TEST -eq 1 ] ; then
                IFS=$OLD_IFS
                for service in ${WATCHDOG_TARGETS[@]}; do
                        #Test server
                        netcat -z -w ${WATCHDOG_TIMEOUT} $(echo $service | cut -f1 -d:) $(echo $service | cut -f2 -d:)
                        if [ $? -ne 0 ] ; then
				logger -p WARNING -t RASH "$service nicht erreichbar! Exec: ${WATCHDOG_TARGET_COMMAND} $service"
                                ${WATCHDOG_TARGET_COMMAND} $service
                        fi
                done
        fi
        sleep 5
done
exit 0

