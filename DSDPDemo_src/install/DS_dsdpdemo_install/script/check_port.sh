#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_port
# Description : check the port that will be used is available or not.
# parameter list:null
# Output      : None
# Return      : 1 failure
#               0 success
#################################################################################
function check_port
{
	typeset log_prefix="function check_port::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
	typeset -i flag=0
	
	get_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR BASIC_INSTALL "Getting selected ne list failed."
		return 1
	fi
	typeset selected_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		selected_ne_list="${selected_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG BASIC_INSTALL "Selected NE list: ${selected_ne_list}."
	typeset global_user_home=""
	typeset global_user_name=""
	typeset ne_name=""

	for ne_name in $selected_ne_list
	do
		cfg_get_sec_key_values "${ne_rela_config}" "PORT-COMPONENT-REF" "${ne_name}"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "BASIC_INSTALL" "${log_prefix} invoke cfg_get_sec_key_values ${segment_name} ${ne_name} error!"
			return 1
		fi
		
		typeset port_check_list=""
		typeset tmp_idx=0
		while [ ${tmp_idx} -lt ${RETNUM} ]
		do
			port_tmp=$(echo ${RETURN[${tmp_idx}]} | sed "s/,/ /g")
			port_check_list="${port_check_list} ${port_tmp}"
			((tmp_idx=tmp_idx+1))
		done

		for port_item in $port_check_list
		do
			read_value "${port_item}"
			if [ $? -ne 0 ]; then
				install_log DEBUG LIB "Getting ${port_item} failed."
				return 1
			fi
			typeset port="${RETURN[0]}"

			port_is_available "${port}"
			if [ $? -ne 0 ]; then
				((flag=flag+1))
				install_log "ERROR" "CHECK_ENV" "The port(${port}) has been used."
			fi
		done
	done
	
	if [ ${flag} -gt 0 ]; then
		return 1
	fi
}