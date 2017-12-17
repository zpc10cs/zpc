#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi
#################################################################################
dm_type=""
oracle_user_home=""
oracle_home=""
standby_oracle_home=""


function check_oracle
{
	get_host_type
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "invoke function: get_host_type failed."
		return 1
	fi
	dm_type="${RETURN[0]}"
	
	oracle_user_home=$(awk -F: '/^oracle:/ {print $6}' /etc/passwd)
	if [ -n "${oracle_user_home}" ]; then
		is_install_oracle
		if [ $? -ne 0 ]; then
			install_log "ERROR" "CHECK_ENV" "invoke function: is_install_oracle failed."
			return 1
		fi

		oracle_home=`su - oracle -c "env | grep ORACLE_HOME | awk -F= '{print \\$NF}'"`
		if [ "X${oracle_home}" = "X" ]; then 
			install_log "ERROR" "CHECK_ENV" "Getting oracle_home failed, please check ORACLE_HOME."
			return 1
		fi
        typeset db_lang=`su - oracle -c "env | ${GREP} ^NLS_LANG | ${AWK} -F= '{print \\$2}'"`
        
        if [ "x${db_lang}" != "x" ]
        then
            if [ "x${db_lang}" != "xAMERICAN_AMERICA.AL32UTF8" ]
            then
                install_log "ERROR" "CHECK_ENV" "Checking oracle env NLS_LANG error.Current value is ${db_lang} and the right value is AMERICAN_AMERICA.AL32UTF8."
                return 1
            else
                install_log "INFO" "CHECK_ENV" "db language set OK."
            fi
        else
            install_log "ERROR" "CHECK_ENV" "can not get the oracle user's nls_lang environment value!"
            return 1
        fi
        
        install_log "DEBUG" "CHECK_ENV" "check database language complete."
        
	else
		install_log "DEBUG" "CHECK_ENV" "The oracle_user or oracle_user_home is not exist."
		install_log "ERROR" "CHECK_ENV" "Please check if you have installed the oracle app."
		return 1
	fi
	
	typeset opposite_ip=""
	if [ "X${dm_type}" = "Xmaster" ]; then 
		read_value "_hostip.1"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "CHECK_ENV" "read_value _hostip.1 value failed."
			return 1
		fi
		opposite_ip=${RETURN[0]}
		#DTS2012082903892 x00193019
		typeset standby_oracle_home=$(ssh root@${opposite_ip} "su - oracle -c\"env|grep -w ORACLE_HOME \"" |awk -F= '{print $2}')
		if [ "X${standby_oracle_home}" = "X" ];then
			sleep 10
			standby_oracle_home=$(ssh root@${opposite_ip} "su - oracle -c\"env|grep -w ORACLE_HOME \"" |awk -F= '{print $2}')
		fi
		
		if [ "X${standby_oracle_home}" = "X" ]; then
			install_log "ERROR" "CHECK_ENV" "Getting standby_oracle_home failed, please check standby oracle home."
			return 1
		fi
		
		if [ "${oracle_home}" != "${standby_oracle_home}" ]; then
			install_log "ERROR" "CHECK_ENV" "oracle_home is not equals standby_oracle_home failed, please check oracle home."
			return 1
		else
			install_log "INFO" "CHECK_ENV" "oracle_home equals standby_oracle_home."
		fi
	fi
	
}

################################################################################
# name  : is_install_oracle
# desc  : check is install oracle app.
# params: $oracle_user_home
# input : null
# output: null
# return: 0 succ, 1 failed
################################################################################
function is_install_oracle
{
	install_log "DEBUG" "CHECK_ENV" "Begin to check if is installed oracle app."
	
	oracle_user_home=$(awk -F: '/^oracle:/ {print $6}' /etc/passwd)
	if [ -d "${oracle_user_home}" ]; then
		typeset plsql_value=`su - oracle -c "which sqlplus"`
		if [ "X${plsql_value}" = "X" ]; then 
			install_log "DEBUG" "CHECK_ENV" "The sqlplus is null."
			install_log "ERROR" "CHECK_ENV" "The oracle app is not installed."
		fi
	else
		install_log "ERROR" "CHECK_ENV" "The oracle_user_home ${oracle_user_home} is not exist. Please check it."
		return 1
	fi

	install_log "DEBUG" "CHECK_ENV" "Checking if is installed oracle app complete."
	return 0
}



