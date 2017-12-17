#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_ip
# Description :check the configuration ip.
# parameter list:null
# Output      : None
# Return      : 1 failure
#               0 success
################################################################################
function check_ip
{	
	typeset log_prefix="function check_ip::"
	
	typeset ip_flag=0
	
	#dm_type,single	
	if [ "x${dm_type}" != "xsingle" ]; then		
		
		install_log "INFO" "CHECK_ENV" "The float ip is ${float_ip}."
		
		#check the format of float ip is right 				
		is_ip_address "${float_ip}"
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_ip_address ${float_ip} failed."
			install_log "ERROR" "CHECK_ENV" "Config ip[$float_ip] is not a ip address."
			((ip_flag=ip_flag+1))
		fi
		
		#check the ip has been configed in /etc/hosts
		#typeset floatip=`cat /etc/hosts | ${GREP} "^${float_ip}" | ${AWK} '{print $1}'`
        #if [ "X$floatip" = "X" ];then     
        #    install_log "WARN" "CHECK_ENV" "The float ip($float_ip) was not configured in /etc/hosts." 
        #fi   
		
		install_log "INFO" "CHECK_ENV" "The standby ip is ${standby_ip}."
		
		#check the format of standby ip is right			
		is_ip_address "${standby_ip}"		
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_ip_address ${standby_ip} failed."
			install_log "ERROR" "CHECK_ENV" "The standby ip[$standby_ip] is not a ip address."
			((ip_flag=ip_flag+1))
		fi
		
		#check the ip has been configed in /etc/hosts
		typeset standip=`cat /etc/hosts | ${GREP} "^${standby_ip}" | ${AWK} '{print $1}'`
        if [ "X${standip}" = "X" ];then
            install_log "WARN" "CHECK_ENV" "The standby ip(${standby_ip}) was not configured in /etc/hosts." 
        fi 
	fi
	
	#host ip
	
	install_log "INFO" "CHECK_ENV" "The host ip is ${host_ip}."
	
	#check the format of host ip is right	
	is_ip_address "${host_ip}"		
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_ip_address ${host_ip} failed."
		install_log "ERROR" "CHECK_ENV" "The host ip[$host_ip] is not a ip address."
		((ip_flag=ip_flag+1))
	fi
	
	typeset localhost_first_flag=$(cat /etc/hosts | grep -w "localhost" | head -1 | grep -w "^127.0.0.1")
	typeset localhost_flag=$(cat /etc/hosts | ${GREP} -w "^127.0.0.1" | ${GREP} -w "localhost")
    
	#config "127.0.0.1  localhost" in /etc/hosts as the first effective configuration
	if [ "x${localhost_first_flag}" = "x" ];then	
		#"127.0.0.1  localhost" is configed in /etc/hosts but not the first effective configuration
		if [ "x${localhost_flag}" != "x" ];then
			install_log "INFO" "CHECK_ENV" "\"127.0.0.1  localhost\" was not the first configuration in /etc/hosts, delete it now."
			sed -i "/^127.0.0.1/{/localhost/d}" /etc/hosts 1>/dev/null 2>&1
		fi
		install_log "INFO" "CHECK_ENV" "localhost was not configured in /etc/hosts, config it now."
		#insert "127.0.0.1  localhost" to /etc/hosts as the first effective configuration
		typeset insert_num=$(sed -n '/^[^#]/=' /etc/hosts | head -1)
		if [ "x${insert_num}" = "x" ];then
			echo "127.0.0.1       localhost" >> /etc/hosts
			if [ $? -ne 0 ];then
				install_log "ERROR" "CHECK_ENV" "configure localhost in /etc/hosts failed."
				return 1
			fi
			install_log "INFO" "CHECK_ENV" "localhost has been configured into /etc/hosts."
		else
			sed -i "${insert_num} i 127.0.0.1       localhost" /etc/hosts
			if [ $? -ne 0 ];then
				install_log "ERROR" "CHECK_ENV" "configure localhost in /etc/hosts failed."
				return 1
			fi
			install_log "INFO" "CHECK_ENV" "localhost has been configured into /etc/hosts."			
		fi
	fi
	
    #############################check is localhost has been bandled to more than one network card or not
	get_localhost_ip
	if [ $? -ne 0 ]; then
		install_log "ERROR" "read_value" "invoke function:get_localhost_ip failed."
		return 1
	fi
	local_host_ip="${RETURN[0]}"
	if [ "x${dm_type}" != "xsingle" ]; then
		typeset bandlenum=`ifconfig | grep -v "#" | grep "inet addr:${local_host_ip}" | wc -l`
		if [ ${bandlenum} -gt 1 ]; then
			install_log "ERROR" "CHECK_ENV" "localhost ip:${local_host_ip} has been bandled to ${bandlenum} network cards, please modify it manually, make sure that host_ip:${local_host_ip} only being bandled to one network card."
		fi
	fi
	#####################################################################################################
    #the cmanager component must config the host ip
	typeset -i comp_idx=1
	typeset -i is_contain_cmanager=0
	typeset comp_name=""
	typeset -i subComp_idx=0
	typeset -i subComp_count=0
	while [ ${comp_idx} -le ${comp_arr[0]} ]
	do
		comp_name="${comp_arr[${comp_idx}]}"
		#get subcomponents by component
		get_subComp_by_component "${comp_name}"
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_subComp_by_component ${comp_name} error!"
			install_log "ERROR" "CHECK_ENV" "Getting the component info failed."
			((ip_flag=ip_flag+1))
		else
			subComp_count=${RETNUM}
			while [ ${subComp_idx} -lt ${subComp_count} ]
			do
				typeset subComp_arr[${subComp_idx}]="${RETURN[${subComp_idx}]}"
				((subComp_idx=subComp_idx+1))
			done
			
			#reset subComp_idx = 0
			subComp_idx=0
			while [ ${subComp_idx} -lt ${subComp_count} ]
			do
				if [ "x${subComp_arr[${subComp_idx}]}" = "xcmanager" ]
				then
					is_contain_cmanager=1
					break 2
				fi
				((subComp_idx=subComp_idx+1))
			done
		fi
		#reset subComp_idx = 0
		subComp_idx=0
		((comp_idx=comp_idx+1))
	done
	
	if [ ${is_contain_cmanager} -eq 1 ]
	then
		typeset hostname=`cat /etc/hosts | ${GREP} "^${host_ip}" | ${AWK} '{print $NF}'`
		if [ "x${hostname}" = "x" ]
		then
			install_log "ERROR" "CHECK_ENV" "the host ip(${host_ip})'s name was not configured in /etc/hosts."
			((ip_flag=ip_flag+1))
		fi
	fi
    
    if [ ${ip_flag} -gt 0 ]; then
    	return 1
    fi
    
    install_log "INFO" "CHECK_ENV" "Checking ip complete."	
}
################################################################################
# name    : is_ip_address
# describe: check the format of ip is right
# parameter list: $1 ip address
# Output      : None
# Return      : 1 failure
#               0 success
################################################################################
function is_ip_address
{
   	typeset log_prefix="function check_ip::"
   
    typeset	ip_str=""
    typeset	old_ifs=""
    typeset -i index=0
    typeset dot_ip=""
    typeset flag=""
    typeset length_str=""

    if [ $# -ne 1 ];then
    	install_log "DEBUG" "CHECK_ENV" "${log_prefix} the function  parameter error."
    	return 1
    fi
    if [ "X$1" = "X" ];then
    	install_log "DEBUG" "CHECK_ENV" "${log_prefix} ip is null string."
        return 1
    fi
    
    ip_str="$1"
    
    typeset eip=`echo "${ip_str}" | ${GREP} "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}$"`
    if [ "X${eip}"  = "X" ];then
        return 1
    fi

    old_ifs="$IFS"
    IFS="."
    index=0
    for dot_ip in ${ip_str}
    do
       if [ "X${dot_ip}" = "X" ];then
            IFS="${old_ifs}"
            return 1    
       fi
       length_str=`echo "${dot_ip}" | ${SED} 's/[0-9][0-9]*//g' | ${AWK} '{print length($0)}'`
       if [ ${length_str} -ne 0 ];then
            IFS="${old_ifs}"
            return 1
    
       fi
       if  [ ${dot_ip} -gt 255 ];then
            IFS="${old_ifs}"
            return 1
       fi
       if [ "X${dot_ip}" = "X0" ];then
           ((index+=1))
           continue
       fi

       echo ${dot_ip} | ${GREP} "^[1-9]" >/dev/null
       if [ $? -ne 0 ]; then
	   	   IFS="${old_ifs}"
           return 1
       fi
       ((index+=1))
    done
    
    IFS="${old_ifs}"
    
    if [ ${index} -ne 4 ];then
    	return 1
    fi
  
}

function check_ip_bond
{
	typeset flag=0

	get_host_type
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "LIB" "get host type failed."
		return 1	
	fi
	typeset local_type="${RETURN[0]}"
			
	get_nic_name
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "LIB" "get service nic name failed."
		return 1	
	fi
	typeset service_nic="${RETURN[0]}"
	
	ifconfig ${service_nic} >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		install_log "ERROR" "LIB" "nic name[${service_nic}] fill in error, please check."
		return 1
	fi
	
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "LIB" "get local ne name failed."
		return 1		
	fi
	typeset ne_num="${RETNUM}"
		
	typeset local_ne_list=""
	typeset index=0
	while [ $index -lt $ne_num ] 
	do
		if [ "x${local_ne_list}" != "x" ];then
			local_ne_list="${local_ne_list} ${RETURN[${index}]}"
		else
			local_ne_list="${RETURN[${index}]}"
		fi
		((index=index+1))
	done
	
	for ne_key in ${local_ne_list}
	do
		get_node_install_index "${ne_key}"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "LIB" "get ne[${ne_key}] index failed."
			((flag=flag+1))
			continue
		fi
		typeset ne_index="${RETURN[0]}"
		
		get_ne_info "${ne_key}"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "LIB" "get ne info[${ne_key}] failed."
			((flag=flag+1))
			continue
		fi

		typeset idx=0
		while [ ${idx} -lt ${NE_NODE_NUM} ]
		do			
			if [ $idx -eq $ne_index ]; then
				if [ "x${local_type}" = "xsingle" ]; then
					service_ip="${NE_HOST_IP[$idx]}"
									
					ifconfig | grep -w "addr:${service_ip}" >/dev/null 2>&1
					if [ $? -ne 0 ]; then
						install_log "ERROR" "LIB" "Current ne[${ne_key}] ip[${service_ip}] is not bound in the current machine."
						((flag=flag+1))
					fi				
				elif [ "x${local_type}" = "xmaster" ]; then
					ifconfig | grep -w "addr:${NE_HOST_IP[$idx]}" >/dev/null 2>&1
					if [ $? -ne 0 ]; then
						install_log "ERROR" "LIB" "Current ne[${ne_key}] ip[${service_ip}] is not bound in the current machine."
						((flag=flag+1))
					fi	
				else
					standby_ip="${NE_STANDBY_IP[$idx]}"					
					ifconfig | grep -w "addr:${standby_ip}" >/dev/null 2>&1
					if [ $? -ne 0 ]; then
						install_log "ERROR" "LIB" "Current ne[${ne_key}] ip[${standby_ip}] is not bound in the current machine."
						((flag=flag+1))
					fi				
				fi					

			fi
			
			((idx=idx+1))
		done
	done
	
		
	if [ ${flag} -gt 0 ]; then
		return 1
	fi
}


