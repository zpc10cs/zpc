#!/usr/bin/ksh

#enter into script dir
if [ `echo "$0" |grep -c "/"` -gt 0 ]; then
	cd ${0%/*}
fi

#include common shell library
. ./commonlib.inc

################################################################################
# name    : dsdp_status_check
# describe: entry of check status.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function dsdp_status_check
{
	# get ne list in local host
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_STATUS_CHECK "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	
	typeset idx=0
	typeset ne_name=""
	for ne_name in ${local_ne_list}
	do
		read_value "appuser_compment_ref"
		if [ $? -ne 0 ];then
			install_log ERROR APP_INSTALL "get appuser_compment_ref value failed."
			return 1
		fi
		typeset select_ne_name=$(echo ${RETURN[0]} | sed 's/,/ /')
	
		read_value "user_name"
		if [ $? -ne 0 ];then
			install_log ERROR APP_INSTALL "get user_name value  failed."
			return 1		
		fi
		ne_user_name="${RETURN[0]}"
		
		read_value "user_password"
		if [ $? -ne 0 ];then
			install_log ERROR APP_INSTALL "get user_password value  failed."
			return 1		
		fi
		pwd_tmp="${RETURN[0]}"
		decodePwd "${pwd_tmp}"
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "decode password failed."
			((flag=flag+1))
		fi
		ne_user_password="${RETURN[0]}"
		
		read_value "user_home"
		if [ $? -ne 0 ];then
			install_log ERROR APP_INSTALL "get user_home value  failed."
			return 1		
		fi
		ne_user_home="${RETURN[0]}"
		
		echo "${select_ne_name}" | grep "${ne_name}" > /dev/null
		if [ $? -eq 0 ];then
			typeset lower_ne=`echo ${ne_name}|tr '[A-Z]' '[a-z]'`
			su - "${ne_user_name}" -c "status -m all" > run.log
		fi
        grep 'not ok' run.log > /dev/null || grep 'stopped' run.log > /dev/null || grep 'refused' run.log > /dev/null || grep 'timed out' run.log > /dev/null
		if [ $? -eq 0 ];then
          rm -rf run.log > /dev/null
          su - "${ne_user_name}" -c "status -m all"
          install_log ERROR DSDP_START "The element is not running successfully."
          return 1
		fi
        rm -rf run.log > /dev/null
        su - "${ne_user_name}" -c "status -m all"
        install_log INFO DSDP_START "The element is running successfully."
	done
	
	return 0
}

################################################################################
# name    : calc_component_count
# describe: calculate sub component count for progress display.
# param1  : null
# output  : RETURN[0]
# rerurn  : 0:success
#           1:faild
################################################################################
function calc_component_count
{
    RETURN[0]=""
    typeset component_count=0
    # get ne list in local host
    get_local_ne_list
    if [ $? -ne 0 ]; then
        install_log ERROR DSDP_STATUS_CHECK "Getting ne list in local host failed."
        return 1
    fi
    typeset local_ne_list=""
    typeset tmp_idx=0
    while [ ${tmp_idx} -lt ${RETNUM} ]
    do
        local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
        ((tmp_idx=tmp_idx+1))
    done
    
    for ne_name in ${local_ne_list}
    do
        #get components list
        get_component_by_ne "${ne_name}"
        if [ $? -ne 0 ]; then
            install_log ERROR DSDP_STATUS_CHECK "Getting components list of ne: ${ne_name} failed."
            return 1
        fi
        typeset comp_list=""
        typeset tmp_idx=0
        while [ ${tmp_idx} -lt ${RETNUM} ]
        do
            comp_list="${comp_list} ${RETURN[${tmp_idx}]}"
            ((tmp_idx=tmp_idx+1))
        done
        install_log DEBUG DSDP_STATUS_CHECK "components list of ne(${ne_name}) : ${comp_list}"
        
        #loop for every component
        for comp_id in ${comp_list}
        do
            #get sub components list
            get_subComp_by_component "${comp_id}"
            if [ $? -ne 0 ]; then
                install_log ERROR DSDP_STATUS_CHECK "Getting subcomponent list of component: ${comp_id} failed."
                return 1
            fi
            ((component_count=component_count+${RETNUM}))
        done
    done
	RETURN[0]="${component_count}"
	return 0
}

dsdp_status_check "$@"


