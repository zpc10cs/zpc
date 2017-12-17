#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_os_limit_para
# Description : check limit parameter in current operation system 
#				in file /etc/security/limits.conf 
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_os_limit_para
{
	return 0
	typeset log_prefix="function check_os_limit_para::"
	typeset filename="/etc/security/limits.conf"
	typeset key_list[0]="nofile"
	typeset key_list[1]="memlock"
	typeset key_list[2]="core"
	typeset key_list[3]="data"
	typeset key_list[4]="nproc"
	typeset value_list[0]="4096"
	typeset value_list[1]="32"
	typeset value_list[2]="2097152"
	typeset value_list[3]="2097152"	
	typeset value_list[4]="2048"
	
	if [ ! -f ${filename} ]
	then
		install_log "ERROR" "${log_prefix}" "${filename} is not existing."
		return 1
	fi	

	typeset flag=0
	typeset username=""
	typeset cbe_user_name=""
	typeset smdb_user_name=""
	typeset uoa_user_name=""
	ne_user_name=""

	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log "ERROR" "${log_prefix}" "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	local_ne_list=$(echo $local_ne_list|sed 's/^\s*//')
	install_log "DEBUG" "${log_prefix}" "NE list in local host: ${local_ne_list}."
	typeset ne_name=""
	for ne_name in ${local_ne_list}
	do
		get_user_by_component "${ne_name}"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "${log_prefix}" "Getting username of component: ${ne_name} failed."
			return 1
		fi
		typeset ne_user_name_cfg_key="${RETURN[0]}"
		if [ "X${ne_user_name_cfg_key}" != "X" ]; then
			read_value "${ne_user_name_cfg_key}_user_name"
			if [ $? -ne 0 ]; then
				install_log "ERROR" "${log_prefix}" "Reading config item: ${ne_user_name_cfg_key}_user_name failed."
				return 1
			fi
			ne_user_name="${RETURN[0]}"
		fi
		
		typeset idx=0
		while [ ${idx} -lt 5 ]
		do	
			typeset line_list_1=$(grep -v "#" "${filename}" | grep "${key_list[${idx}]}" | grep "\*" | grep "-")
			if [ "x${line_list_1}" != "x" ];then
				sed -i "/${line_list_1}/d" "${filename}"
			fi
			typeset line_list=$(grep -v "#" "${filename}" | grep "${key_list[${idx}]}" | grep -w "${ne_user_name}" | grep "-")
			if [ "x${line_list}" != "x" ];then
				typeset line_list_lastline=$(grep -v "#" "${filename}" | grep "${key_list[${idx}]}" | grep "${ne_user_name}" | grep "-" | sed '/^[ \t]*$/d' | sed -n '$p')
				typeset -i value=$(echo "${line_list_lastline}" | awk '{print $4}')
				if [ ${value} -ne ${value_list[${idx}]} ];then
					typeset line="${ne_user_name} - ${key_list[${idx}]} ${value_list[${idx}]}"
					sed "s/${line_list_lastline}/${line}/g" "${filename}" >> "${filename}_$$"
					mv -f "${filename}_$$" "${filename}"
				fi
			else
				echo "${ne_user_name} - ${key_list[${idx}]} ${value_list[${idx}]}" >> "${filename}"
			fi
			((idx=idx+1))
		done
		
	done
	
	typeset user_name=""
	if [ "x${username}" != "x" ]; then
		for user_name in ${username}
		do
			flag=$(grep -v "#" "${filename}" | grep "^[ \t]*${user_name} - stack.*" | wc -l)
			if [ ${flag} -ne 0 ]; then
				sed "s#^[ \t]*${user_name} - stack.*##g" "${filename}" >fg_tmp
				if [ $? -ne 0 ]; then
					install_log "ERROR" "${log_prefix}" " there is a ${user_name} in file ${filename}, please delete it manually."
					return 1
				else
					mv fg_tmp ${filename}
				fi
			fi
		done
	fi

}

