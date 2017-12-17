#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_os_patch
# Description : check whether the necessary os patch is add or not..
# parameter list:
#                null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_os_patch
{
	typeset log_prefix="function check_os_patch::"
	typeset -i flag=0
	
    typeset os=`uname`
    
  	read_value "${env_std_cfg}" "${os}_patch_amount" 
    if [ $? -ne 0 ]; then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value ${env_std_cfg} ${os}_patch_amount error !" 
        install_log "ERROR" "CHECK_ENV" "Checking operation system patch failed."
        return 1
    fi
        
    typeset patch_count="${RETURN[0]}"
    typeset i=1;
    
    install_log "INFO" "CHECK_ENV" "The require os patch amount is ${patch_count}"
    
    while [ ${i} -le ${patch_count} ]
    do
    	install_log "INFO" "CHECK_ENV" "begin to check ${os}_patch_${i}."
    	
        read_value "${env_std_cfg}" "${os}_patch_${i}"
        if [ $? -ne 0 ]; then
           install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value ${env_std_cfg} ${os}_patch_${i} error !" 
           install_log "ERROR" "CHECK_ENV" "Checking ${os}_patch_${i} failed."
           ((flag=flag+1))
        else
	        typeset patch=${RETURN[0]}
	        install_log "INFO" "CHECK_ENV" "the ${os}_patch_${i} is ${patch}" 
	                    
	        typeset value=`SPident -vv | ${AWK} '{print $1}' | ${GREP} "^${patch}"\$`               
	        if [ "X$value" = "X" ]; then
	        	install_log "ERROR" "CHECK_ENV" "The ${patch} can not find in current operation system!"
	        	((flag=flag+1))
	        else
	        	install_log "INFO" "CHECK_ENV" "The ${patch} has already installed."
	        fi
        fi
        
        install_log "INFO" "CHECK_ENV" "Finish checking ${os}_patch_${i}."
        
        #turn to next patch
        ((i=i+1))
	done
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
   
}
################################################################################
# name	:	judge_install_patch
# describe:	judge current ne need install system patch
# parameter list: null
# input	  : null
# return  : 0: need
#           1: error
#           2: no need
# invoker : install_sys_patch
#####################################################################
function judge_install_patch
{
    read_value "_localNETypeList"
    if [ $? -ne 0 ]; then
        install_log "INFO" "CHECK_ENV" "Getting ne list in localhost failed."
        return 1
    fi
    typeset local_ne_list="${RETURN[0]}"
    if [ $(echo ${local_ne_list} | grep -w "MDCC" | wc -l) -eq 1 ]
    then
        return 0
    fi
    if [ $(echo ${local_ne_list} | grep -w "Charging_with_Dccproxy" | wc -l) -eq 1 ]
    then
        get_localmachine_ne_list
        if [ $? -ne 0 ];then
            install_log "ERROR" "CHECK_ENV" "Getting ne list in local machine failed."   
            return 1
        fi
        typeset tmp_idx=0
        while [ ${tmp_idx} -lt ${RETNUM} ]
        do
            if [ "${RETURN[${tmp_idx}]}" = "MDCC" ]
            then
                return 2
            fi
            ((tmp_idx=tmp_idx+1))
        done
        return 0
    fi 
    return 2
}



