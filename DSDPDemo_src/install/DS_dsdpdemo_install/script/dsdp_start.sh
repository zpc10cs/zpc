#!/usr/bin/ksh

#enter into script dir
if [ `echo "$0" |grep -c "/"` -gt 0 ]; then
	cd ${0%/*}
fi

#include common shell library
. ./commonlib.inc

################################################################################
# name    : dsdp_start
# describe: entry of start.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function dsdp_start
{
	log_echo RATE 0
	install_log INFO DSDP_START "Begin to start."
	    
	# get ne list in local host
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_START "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG DSDP_START "NE list in local host: ${local_ne_list}."

	typeset -i fail_num=0
		
	typeset ne_name=""
    for ne_name in ${local_ne_list}
	do
		install_log INFO DSDP_START "Begin to start net element: ${ne_name}."
				
		#start sub components
		#get user config id prefix
		read_value "user_config.size"
		if [ $? -ne 0 ];then
			install_log ERROR DSDP_START "get user_config.size value failed."
			return 1
		fi
		typeset user_config_size="${RETURN[0]}"
		
		typeset idx=0
		while [ $idx -lt $user_config_size ]
		do
			read_value "user_config.$idx.appuser_compment_ref"
			if [ $? -ne 0 ];then
				install_log ERROR DSDP_START "get user_config.$idx.appuser_compment_ref value failed."
				return 1
			fi
			typeset select_ne_name=$(echo ${RETURN[0]} | sed 's/,/ /')
	
			echo "${select_ne_name}" | grep "${ne_name}"
			if [ $? -eq 0 ];then
				read_value "user_name"
				if [ $? -ne 0 ];then
					install_log ERROR DSDP_START "get user_name value  failed."
					return 1		
				fi
				ne_user_name="${RETURN[0]}"
				
				read_value "user_config.$idx.user_home"
				if [ $? -ne 0 ];then
					install_log ERROR DSDP_START "get user_config.$idx.user_home value  failed."
					return 1		
				fi
				ne_user_home="${RETURN[0]}"
			else
				((idx=idx+1))
				continue
			fi
			su - "${ne_user_name}" -c "startapp all" 
			if [ $? -ne 0 ]; then
				install_log ERROR DSDP_START "starting failed."
				((idx=idx+1))
				((fail_num=fail_num+1))
				continue
			fi
			((idx=idx+1))
			install_log INFO DSDP_START "End to start net element: ${ne_name}."
		done
	done
	
	if [ ${fail_num} -gt 0 ];then
		install_log ERROR DSDP_START "starting some net element failed."
		return 1
	fi
	log_echo RATE 100
	install_log INFO DSDP_START "starting all net element succeed."
	install_log INFO DSDP_START "End to start."
	
	return 0
}

dsdp_start "$@"