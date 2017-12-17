#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_os_version
# Description : check the operation system version whether correct
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_os_version
{
	typeset log_prefix="function check_os_version::"
	typeset os=`uname`
	typeset -i flag=0
	
    typeset os_version=""
    
    os_version=`uname -r | ${AWK} -F- '{ print $1}'`-`uname -r |${AWK} -F - '{print $2}'`
    install_log "INFO" "CHECK_ENV" "The current version is ${os_version}"
           
    read_value "${env_std_cfg}" "${os}"
    if [ $? -ne 0 ]; then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read config item ${os} ${env_std_cfg} failed." 
        return 1
    fi
    
    typeset std_os_version="${RETURN[0]}"
    install_log "INFO" "CHECK_ENV" "The config standard version is ${std_os_version}"
    
    if [[ "X${os_version}" < "X${std_os_version}" ]]; then
        install_log "ERROR" "CHECK_ENV" "The OS version is incorrect,the current version is ${os_version},not higher than config standard version ${std_os_version} !"
        ((flag=flag+1))
	fi
	
	#the DSDP must install in SUSE 10 version
	if [ "x${os}" = "xLinux" ]
	then
		typeset version_info=`lsb_release -i | ${GREP} "SUSE"`
		
		if [ "x${version_info}" != "x" ]
		then
			typeset -i version_num=`lsb_release -r | ${AWK} -F: '{print $2}' | ${SED} -n "s/[ \t]*//gp"`
			
			if [ ${version_num} -lt 11 ]
			then
				install_log "ERROR" "CHECK_ENV" "Current OS version require at least SUSE 11!"
				((flag=flag+1))
			fi
		else
			install_log "ERROR" "CHECK_ENV" "Current OS is not SUSE Linux operating system!"
			((flag=flag+1))
		fi
	fi
	
	install_log "INFO" "CHECK_ENV" "Checking OS version complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}



