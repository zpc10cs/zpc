#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_ssh
# Description : check current machine whether install ssh protocol
# parameter list:null
# Output      : None
# Return      : 1 failure
#               0 success
################################################################################
function check_ssh
{
	install_log "INFO" "CHECK_ENV" "begin checking ssh protocal."
	
	#check whether install ssh server in current user
	typeset sshd_path=`which sshd`
	if [ "x${sshd_path}" = "x" ]
	then
		install_log "ERROR" "CHECK_ENV" "current user(`whoami`) is not install ssh program."
		return 1
	fi
	
	#check whether the ssh server is opened
	typeset chech_ssh_result=`ps -ef | ${GREP} sshd | ${GREP} ${sshd_path} | ${GREP} -v ${GREP}`
    if [ "X${chech_ssh_result}" = "X" ]; then
    	install_log "ERROR" "CHECK_ENV" "The current machine does not open ssh protocol."
        return 1
    fi
    
    install_log "INFO" "CHECK_ENV" "Checking ssh protocal complete."
}



