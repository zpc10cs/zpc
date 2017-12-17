#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

#include common file
. ./commonlib.inc

. ./do_before_check_env.sh

. ./check_install_package.sh

. ./check_os_version.sh

. ./check_os_patch.sh

. ./check_os_kernel_para.sh

. ./check_os_limit_para.sh

. ./check_user.sh

. ./check_db.sh

. ./check_port.sh

. ./check_ip.sh

. ./check_comm.lib

. ./check_oracle.sh

. ./check_ssh.sh

#. ./check_special_lv_size.sh
################################################################################
# name	:	main
# describe:	main function of check environment about DSDP
# parameter list: null
# input	  : null
# output  : 0 success 1 failure
# rerurn  : null
# invoker : main
################################################################################
function check_env
{
	typeset log_prefix="function main::"
	
	#the variable describe whether exit the check_env step when execute error. 
	# 0 continue execute	1 exit
	typeset -i is_continue_check=0
	
	#the variable describe the common total step of all check environment
	typeset -i common_total_step=12
	
	#the rate length of every check step
	typeset -i step_rate=`expr 80 / ${common_total_step}`
	
	typeset -i current_rate=0
	
	#the variable describe the current step index of common_total_step that execute check environment
	typeset -i step_index=1
	
	#the variable count the fail time of check step
	typeset -i fail_num=0
	
	install_log "INFO" "CHECK_ENV" "================================================================================"
	install_log "INFO" "CHECK_ENV" "====                            CHECK ENVIRONMENT BEGIN                     ===="
	install_log "INFO" "CHECK_ENV" "================================================================================"

	#init rate of check_env process
	log_echo "rate" "0"
    #####step next 
    install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Initializing checking global environment>***************"		
	do_before_check_env
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} invoke do_before_check_env error ."				
		#can not initial global,exit the process
		return 1
	fi
		
	
	
	# get ne list in local host
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG APP_INSTALL "NE list in local host: ${local_ne_list}."
	typeset global_user_home=""
	typeset global_user_name=""
	typeset ne_name=""

	read_value "_localNETypeList"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "get oracle_home and oracle_base failed."
		((fail_num=fail_num+1))
	fi

	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>***********************************"
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
    
	#####step next
    install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking the install package>**************************"			
	#the step check current task
	#initial environment variable
	check_install_package
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_install_package error ."					
		#fail time +1
		((fail_num=fail_num+1))
	fi
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>***********************************"
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
    
	#####step next
	install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking operation system version>*********************"			
	#the step do not use user_array and comp_array,so needn't initial again
	check_os_version			
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_os_version error."				
		#fail time +1
		((fail_num=fail_num+1))
	fi
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>***********************************"
	
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
    #####step next 
	install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking operation system user>************************"			
	#the step check current task			
	#initial environment variable
	check_user			
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_user error."					
		#fail time +1
		((fail_num=fail_num+1))
	fi
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>***********************************"
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
	#####step next
	
	read_value "isDBAppSelected"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "get isDBAppSelected value failed."
		return 1
	fi
	typeset isDBAppSelected=${RETURN[0]}
    
    read_value "is_need_db"
    if [ $? -ne 0 ];then
        install_log "ERROR" "DELETE_DB" "get is_need_db value failed."
        return 1
    fi
    typeset is_need_db=${RETURN[0]}	
    
	if [ "X${isDBAppSelected}" = "Xyes" -a "X${is_need_db}" != "XNO" ];then
		install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking database info>********************************"		
		#the step check current task			
		#initial environment variable
		check_db				
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_db error."
			#fail time +1
			((fail_num=fail_num+1))
		fi
		
		#check_oracle
		check_oracle
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "CHECK_ENV" "${log_prefix} invoke check_oracle error."
			((fail_num=fail_num+1))
		fi
	fi
	
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>***********************************"
	
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
    #####step next
	install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking network port>********************************"
	#the step check all virtual task of current machine
	#initial environment variable
	check_port
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_port error."
		#fail time +1
		((fail_num=fail_num+1))
	fi
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>**********************************"
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))
		
	################################################################################
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>**********************************"
	((current_rate=current_rate+step_rate))
	log_echo "rate" "${current_rate}"
	((step_index=step_index+1))

    #####step next
	install_log "INFO" "CHECK_ENV" "*****************<STEP ${step_index}:Checking ssh protocal and rpm>********************************"
	#the step do not use user_array and comp_array,so needn't initial again
	check_ssh
	if [ $? -ne 0 ]
	then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} invoke check_ssh error."
		#fail time +1
		((fail_num=fail_num+1))
	fi	
	install_log "INFO" "CHECK_ENV" "******************************<STEP ${step_index} FINISH>**********************************"
    
	#get final result of check_env
	if [ ${fail_num} -gt 0 ]
	then
		check_result=2
	else
		check_result=1
	fi
	
	#update the result of check_env
	cfg_update_sec_key_value "${step_exec_ret_file}" "install" "env_check" "${check_result}"

	
	#set rate of check_env process
	log_echo "rate" "100"
	install_log "INFO" "CHECK_ENV" "================================================================================="
	install_log "INFO" "CHECK_ENV" "================================CHECK ENVIRONMENT END============================"
	install_log "INFO" "CHECK_ENV" "================================================================================="
	
	typeset bits=`getconf LONG_BIT`
	if [ ${bits} -eq 64 ]
	then 
		cp -f ./libsigar-amd64-linux.so /usr/local/lib		
	else 
		cp -f ./libsigar-x86-linux.so /usr/local/lib
	fi
	
	if [ $? -ne 0 ]
	then
		install_log "ERROR" "CHECK_ENV" "copy libsigar-x86-linux.so or libsigar-amd64-linux.so failed"
		return 1
	fi	
	
	if [ ${check_result} -eq 2 ]
	then
		return 1
	fi
}
################################################################################
#global variable:localhost_ip
#describe	:ip address of current machine
################################################################################
typeset localhost_ip=""

################################################################################
#global variable:ne_list ne_count
#describe	:ne list of current machine
################################################################################
typeset ne_list=""
typeset ne_count=""

################################################################################
#global variable:ne_rela_config
#describe	:ne relative config file
################################################################################
#typeset ne_rela_config="${SCRIPT_DIR}/ne-comp-sub_comp.ini"

################################################################################
#global variable:is_db_server [0|1]  0 false 1 true
#describe	:whether current machine install db server component
################################################################################
typeset -i is_db_server=0

################################################################################
#global variable:comp_arr[]
#describe	:the elements of the component array was installed in current machine
#			comp_arr[0] the first element of the array is number of the array
#			comp_arr[N] the component name of the array
################################################################################
#typeset comp_arr

################################################################################
#global variable:user_arr[]
#describe	:the elements of the user array was created in current machine
#			comp_arr[0] the first element is the number of the array
#			comp_arr[N] the user name of the array
################################################################################
#typeset user_arr

################################################################################
#global variable:
#describe	:database config parameter,dsdp application only support Oracle now
################################################################################
typeset db_type=""
typeset db_oracle_home=""
typeset dual_type=""
typeset db_oracle_sys_type=""
typeset db_oracle_sys_ip=""
typeset db_oracle_sys_standby_ip=""
typeset db_oracle_sys_sid=""
typeset db_oracle_sys_service_name=""
typeset db_oracle_sys_net_service_name=""
typeset db_oracle_sys_port=""
typeset db_oracle_sys_dba_username=""
typeset db_oracle_sys_dba_password=""
typeset db_oracle_sys_username=""
typeset db_oracle_sys_password=""
#oracle OS install user and password
typeset db_os_sys_user=""
typeset db_os_sys_passwd=""
#storyType Local|Device
typeset db_oracle_sys_storageType=""

typeset userdb_size=0
typeset db_oracle_user_type=""
typeset db_oracle_user_ip=""
typeset db_oracle_user_standby_ip=""
typeset db_oracle_user_sid=""
typeset db_oracle_user_service_name=""
typeset db_oracle_user_net_service_name=""
typeset db_oracle_user_port=""
typeset db_oracle_user_dba_username=""
typeset db_oracle_user_dba_password=""
typeset db_oracle_user_username=""
typeset db_oracle_user_password=""
#oracle OS install user and password
typeset db_os_user_user=""
typeset db_os_user_passwd=""
#storyType Local|Device
typeset db_oracle_user_storageType=""

typeset cbedb_size=0
typeset db_oracle_cbedb_type=""
typeset db_oracle_cbedb_ip=""
typeset db_oracle_cbedb_standby_ip=""
typeset db_oracle_cbedb_sid=""
typeset db_oracle_cbedb_service_name=""
typeset db_oracle_cbedb_net_service_name=""
typeset db_oracle_cbedb_port=""
typeset db_oracle_cbedb_dba_username=""
typeset db_oracle_cbedb_dba_password=""
typeset db_oracle_cbedb_username=""
typeset db_oracle_cbedb_password=""
#oracle OS install user and password
typeset db_os_cbedb_user=""
typeset db_os_cbedb_passwd=""
#storyType Local|Device
typeset db_oracle_cbedb_storageType=""

################################################################################
#global variable:client_service_name_str
#describe	:client oracle database config parameter,
#			the form is xxx_net_service_name1|xxx_net_service_name2|...
################################################################################
typeset client_service_name_str=""

################################################################################
#global variable:step_exec_ret_file
#describe	:the file records the execute information of DSDP install
################################################################################
typeset step_exec_ret_file="${IDEPLOY_PKG_PATH}/script/step_exec_ret.ini"

################################################################################
#global variable:env_std_cfg
#describe	:the file records the item of DSDP that need check in check_env
################################################################################
typeset env_std_cfg="${IDEPLOY_PKG_PATH}/script/env_std_cfg.properties"

################################################################################
#global variable:port_ini
#describe	:the file records the item that the port need check whether idle
################################################################################
#typeset port_ini="${IDEPLOY_PKG_PATH}/script/port_check_list.ini"

################################################################################
#global variable:log_file
#describe	:the file records the install log
################################################################################
typeset log_file="${IDEPLOY_PKG_PATH}/log/install.log"

################################################################################
#global variable:port_temp_file
#describe	:the file records the port value that be used by DSDP
#			NOTE:everytime that execute the check_env step must delete the file first!
################################################################################
typeset port_temp_file="${TMP}/port.list"
typeset all_ports_file="${TMP}/ports.list"

################################################################################
#global variable:mout_temp_file
#describe	:the file records the mout info of current machine
################################################################################
typeset mout_temp_file="${TMP}/mout_tmp"

################################################################################
#global variable:user_check_file
#describe	:the file records user and group information in current machine
#			the file was created by check_env step when check user,
#			and then the install step will create user and group depend on the file.
#			the file form is 
#				name=group|user
#			the name is the prefix of the user that belongs to component,the value
#			was setted in [COMPONENT-USER-REF] segment of ne-comp-sub_comp.ini file 
#			
#			the group and user value is 0 or 1.0 express the group or user hasn't installed,
#			and 1 express the group or user has already installed
#
#			NOTE:everytime that execute the check_env step must delete the file first!
################################################################################
#typeset user_check_file="${TMP}/user.chk"

################################################################################
#global variable:check_result
#describe	:the variable describe the final result of check_env.
#			0 init 
#			1 all steps are success 
#			2 maybe some steps fail and need check_env again
################################################################################
typeset -i check_result=0

################################################################################
#global variable:rt_repair_code
#describe	:the variable describe return value of a function invoke.if the return value
#			= rt_repair_code,then need be repaired and don't be return error.
#			Notice:the value must be more than 199
################################################################################
typeset -i rt_repair_code=200

################################################################################
#global variable:is_create_tablespace
#describe	:the flag describe whether create tablespace if the tablespace is not exist
################################################################################
typeset -i is_create_tablespace=1

################################################################################
#global variable:db_temp_config
#describe	:the file records the database info of Checking db
################################################################################
typeset db_temp_file="${TMP}/check_db_config.tmp"

################################################################################
#global variable:db_remote_file
#describe	:the file records the db server information of remote machine
################################################################################
typeset db_remote_file="${TMP}/db_remote_file.tmp"

#execute main function

task_type="INSTALL"

if [ "X${task_type}" = "XINSTALL" ];then
	check_env "$@"
fi




