#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# name	:	do_before_check_env
# describe:	do some necessary step before checking environment
# parameter list: null
# input	  : null
# output  : 0 success 1 failure
# return  : null
# invoker : main
################################################################################
function do_before_check_env
{
	typeset log_prefix="function do_before_check_env::"
	typeset -i flag=0
	
	read_value "isDBAppSelected"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "get isDBAppSelected value failed."
		return 1
	fi
	typeset isDBAppSelected=${RETURN[0]}
	
	if [ "X${isDBAppSelected}" = "Xyes" ];then
		install_log "INFO" "CHECK_ENV" "Begin to initialize the database configuration."

		get_oracle_env
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "CHECK_ENV" "get oracle_home and oracle_base failed."
			((fail_num=fail_num+1))
		fi	
	
		get_db_info
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_db_info error."
			install_log "ERROR" "CHECK_ENV" "Initializing the database configuration failed."
			((flag=flag+1))
		fi
	fi
	

	
	install_log "INFO" "CHECK_ENV" "Initializing the database configuration is complete."

	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# Function    : init_service_ip
# Description : init service ip:check service host[stanby] ip is bond or not
# parameter list:null
# Output      : None
# Return      : 1 failure
#               0 success
################################################################################
function init_config_file
{
	typeset config_file=${IDEPLOY_PKG_PATH}/conf/config.properties
	# only neet to check in the first net element in local physical machine
	# get first ne in local host
	get_localmachine_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting ne list in localmachine failed."
		return 1
	fi
	first_ne_name=${RETURN[0]}
	
	read_value "_localNETypeList"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "read_value _localNETypeList failed."
		return 1
	fi
	typeset tmp_name="${RETURN[0]}"
	grep "compToCreateUser" ${config_file} > /dev/null
	if [ $? -ne 0  ];then		
		echo ${tmp_name}|grep ${first_ne_name} > /dev/null
		if [ $? -ne 0  ];then
			echo "compToCreateUser=${first_ne_name}" >> ${config_file}
		else
			typeset first_ne=`echo ${tmp_name}|awk -F, '{print $1}'`
			echo "compToCreateUser=${first_ne}" >> ${config_file}
		fi
	fi
}
################################################################################
# name	:	adjust_cmos_clock
# describe:	set NTPD_ADJUST_CMOS_CLOCK="yes" 
# parameter list: null
# input	  : null
# output  : 0 success 1 failure
# return  : null
# invoker : main
################################################################################
function adjust_cmos_clock
{
    typeset ntp_file="/etc/sysconfig/ntp"
    if [ -f ${ntp_file} ];then
		typeset is_exist=$(grep "^NTPD_ADJUST_CMOS_CLOCK" ${ntp_file})
		if [ "x${is_exist}" = "x" ]; then
			echo "NTPD_ADJUST_CMOS_CLOCK=\"yes\"" >> ${ntp_file}
		else
			sed -i 's/NTPD_ADJUST_CMOS_CLOCK=\"no\"/NTPD_ADJUST_CMOS_CLOCK=\"yes\"/' ${ntp_file}
			if [ $? -ne 0 ];then
				install_log "ERROR" "CHECK_ENV" "Change the value of NTPD_ADJUST_CMOS_CLOCK to yes in /etc/sysconfig/ntp failed."
				return 1
			fi
		fi	
    fi
}
################################################################################
# name	:	open_xinetd
# describe:	open service echo for keep xinetd on
# parameter list: null
# input	  : null
# output  : 0 success 1 failure
# return  : null
# invoker : main
################################################################################
function open_xinetd
{
	chkconfig -s echo xinetd
	if [ $? -ne 0 ];then
		install_log ERROR CHECK_ENV "exec commond \"chkconfig -s echo xinetd\" failed"
		return 1
	fi
}
