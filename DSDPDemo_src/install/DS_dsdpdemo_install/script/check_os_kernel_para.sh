#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_os_kernel_para
# Description : check kernel parameter in current operation system  
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_os_kernel_para
{	
	typeset log_prefix="function check_os_kernel_para::"
	typeset cfg_file="${IDEPLOY_PKG_PATH}/script/sysctl.conf"
	typeset cfg_file_bak="${IDEPLOY_PKG_PATH}/script/sysctl.conf.bak"
	
	if [ ! -f ${cfg_file} ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} can't find the file ${cfg_file}."
		return 1
	fi
	
	MemTotal=$(cat /proc/meminfo | grep MemTotal | awk -F: '{print$2}' | awk '{print$1}')
	if [ "x${MemTotal}" = "x" ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} get MemTotal info from /proc/meminfo failed."
		return 1
	fi
	kernel_shmall=$(expr ${MemTotal} / 4)
	
	cp "${cfg_file}" "${cfg_file_bak}"
	update_cfg_value "${cfg_file_bak}" "kernel.shmall" "${kernel_shmall}"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} update ${cfg_file_bak} kernel.shmall to ${kernel_shmall} failed."
		return 1
	else
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} update ${cfg_file_bak} kernel.shmall to ${kernel_shmall}."
	fi
	cp "${cfg_file_bak}" "${cfg_file}"
	rm "${cfg_file_bak}"

	# only neet to check in the first net element in local physical machine
	get_localmachine_ne_list
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} gettting first net element in local physical machine failed."
		return 1
	fi	
	typeset firstne="${RETURN[0]}"
	install_log "INFO" "CHECK_ENV" "${log_prefix} the first net element in local physical machine is: ${firstne}."

	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} gettting all net elements installed by current install user failed."
		return 1
	fi
	typeset check_flag=0
	typeset idx=0
	while [ ${idx} -lt ${RETNUM} ]
	do
		if [ "X${RETURN[${idx}]}" = "X${firstne}" ]; then
			install_log "INFO" "CHECK_ENV" "${log_prefix} the first net element in local physical machine(${firstne}) installed by current install user, so need to check os kernel parameters."
			check_flag=1
		fi
		
		((idx=idx+1))
	done

	if [ ${check_flag} -eq 0 ]; then
		install_log "INFO" "CHECK_ENV" "${log_prefix} the first net element in local physical machine(${firstne}) is not installed by current install user, so need not check os kernel parameters, skip it."
		return 0
	fi

    if [ -f /etc/sysctl.conf ]; then
		# backup /etc/sysctl.conf
		if [ ! -f "/etc/sysctl.conf.bak" ]; then
			cp /etc/sysctl.conf /etc/sysctl.conf.bak
		fi

		# delete old parameter
		while read line
		do
			line=$(echo "${line}" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
			echo "${line}" | grep '^#' > /dev/null 2>&1
			if [ $? -eq 0 -o "X${line}" = "X" ]; then
				continue
			fi
			
			typeset kkey=$(echo "${line}" | awk -F= '{ print $1; }' | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')
			# delete old parameter in /etc/sysctl.conf
			sed -i "/^[ \t]*${kkey}[ \t]*=/d" /etc/sysctl.conf
		done < ${cfg_file}
		
		# delete '#BEGIN FOR DSDP' and '#END FOR DSDP' and '# for DSDP'
		sed -i '/^#.*DSDP/d' /etc/sysctl.conf
		
		# delete blank line
		sed -i '/^[ \t]*$/d' /etc/sysctl.conf
		
		# append DSDP kernel parameters to system kernel parameters
		echo '' >> /etc/sysctl.conf
        cat ${cfg_file} >> /etc/sysctl.conf
    else
        install_log "WARN" "CHECK_ENV" "/etc/sysctl.conf file not exist,so cp ${cfg_file} as /etc/sysctl.conf"
        
        #copy the config file and active the configuration
        cp ${cfg_file} /etc/sysctl.conf
        chmod 755 /etc/sysctl.conf
        insserv boot.sysctl > /dev/null 2>&1
        /etc/init.d/boot.sysctl start | sed '$d'
    fi

	#activate the kernel parameter: /etc/sysctl.conf
	/sbin/sysctl -p > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		install_log "ERROR" "CHECK_ENV" "reset the core parameter of os failed."
		return 1
	else
		install_log "INFO" "CHECK_ENV" "reset the core parameter of os success."
	fi
 	
    if [ ! -d /dump ]; then
        mkdir /dump
        if [ $? -ne 0 ]; then
            install_log "ERROR" "CHECK_ENV" "creating the directory dump failed ."
        else
            install_log "INFO" "CHECK_ENV" "creating the directory dump succeded."
        fi
    else
        install_log "INFO" "CHECK_ENV" "the directory dump has already exist."        
    fi
    chmod 777 /dump
    if [ $? -ne 0 ]; then
        install_log "ERROR" "CHECK_ENV" "modify the right of directory dump failed ."
    else
        install_log "INFO" "CHECK_ENV" "modify the right of directory dump succeded."
    fi
 	install_log "INFO" "CHECK_ENV" "Checking kernel parameter complete."
}



