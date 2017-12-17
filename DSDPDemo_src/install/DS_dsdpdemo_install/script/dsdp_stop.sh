#!/usr/bin/ksh

#enter into script dir
if [ `echo "$0" |grep -c "/"` -gt 0 ]; then
	cd ${0%/*}
fi

#include common shell library
. ./commonlib.inc

################################################################################
# name    : dsdp_stop
# describe: entry of stop.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function dsdp_stop
{
	log_echo RATE 0
	install_log INFO DSDP_STOP "Begin to start."
		
	log_echo RATE 5
	PROGRESS_MAX=5
    
	# get ne list in local host
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_STOP "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG DSDP_STOP "NE list in local host: ${local_ne_list}."

		
	typeset ne_name=""
    for ne_name in ${local_ne_list}
	do
		install_log INFO DSDP_STOP "Begin to start net element: ${ne_name}."
				
		#start sub components
		#get user config id prefix
		read_value "user_config.size"
		if [ $? -ne 0 ];then
			install_log ERROR DSDP_STOP "get user_config.size value failed."
			return 1
		fi
		typeset user_config_size="${RETURN[0]}"
		
		typeset idx=0
		while [ $idx -lt $user_config_size ]
		do
			read_value "user_config.$idx.appuser_compment_ref"
			if [ $? -ne 0 ];then
				install_log ERROR DSDP_STOP "get user_config.$idx.appuser_compment_ref value failed."
				return 1
			fi
			typeset select_ne_name=$(echo ${RETURN[0]} | sed 's/,/ /')
	
			echo "${select_ne_name}" | grep "${ne_name}"
			if [ $? -eq 0 ];then
				read_value "user_name"
				if [ $? -ne 0 ];then
					install_log ERROR DSDP_STOP "get user_name value  failed."
					return 1		
				fi
				ne_user_name="${RETURN[0]}"
				
				read_value "user_config.$idx.user_home"
				if [ $? -ne 0 ];then
					install_log ERROR DSDP_STOP "get user_config.$idx.user_home value  failed."
					return 1		
				fi
				ne_user_home="${RETURN[0]}"
			else
				((idx=idx+1))
				continue
			fi
			
			pkill -9 -u ${ne_user_name}
			((idx=idx+1))
		done
		install_log INFO DSDP_STOP "End to start net element: ${ne_name}."
	done
	
	log_echo RATE ${PROGRESS_MAX}
	install_log INFO DSDP_STOP "Stopping all net element succeed."
	
	log_echo RATE 100
	install_log INFO DSDP_STOP "End to start."
	
	return 0
}

dsdp_stop "$@"