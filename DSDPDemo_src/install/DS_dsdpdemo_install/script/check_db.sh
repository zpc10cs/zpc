#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

#include common shell library
. ./commonlib.inc
################################################################################
# Name       : check_db.sh
# Describe   : check databse function shell library for developers.
# Date       : 2008-11-20
# Functions  :
#			   check_db
#			   check_db_server
#			   check_sysdb
#			   check_userdb
#			   check_cbedb
#			   check_bfmdb
#			   check_sysdb_space
#			   check_userdb_space
#			   check_cbedb_space
#			   check_bfmdb_space
#			   db_space
#			   check_userdb_user
#			   check_sysdb_user
#			   check_bfmdb_user
#			   check_cbedb_user
#			   is_db_user_exit
#			   get_db_info
#			   init_ora_env
#			   init_db_server_info
#			   init_db_server_sys_info
#			   init_db_server_user_info
#			   init_db_server_cbe_info
#			   get_db_server_flag
#			   check_db_client
#			   check_enip_client
#			   check_cbe_client
#			   check_other_client
#			   check_special_client
#			   check_slcc_special_client
#			   is_tnsping_ok
#			   execute_tnsping
#			   parse_tns_config
#			   get_tns_config_by_key
#			   check_db_lang
#			   parse_failure_file
#			   add_tns_config
#			   check_lcap_db_server
#			   check_onesdp_db_server
#			   check_lcapdb
#			   init_db_server_lcap_info
################################################################################

################################################################################
# Function    : check_db
# Description : check the database configuration is correct or not.
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_db
{
	typeset log_prefix="function check_db::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
	typeset -i flag=0
	
	#create temp check file
	touch ${db_temp_file}
	
	get_db_info
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_db_info failed."
		install_log "ERROR" "CHECK_ENV" "get database configuration failed. ${log_suffix}"
		return 1
	fi


	#check db client
	if [ ${is_db_server} -eq 1 ]; then
		check_db_server
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_db_server failed."
			((flag=flag+1))
		fi
	fi
		
	#delete temp check file
	rm -rf ${db_temp_file}
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# Function    : check_db_user_privs
# Description : check database db user privilege whether correct or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_db_user_privs
{
	typeset dba_username=$1
	typeset dba_password=$2
	typeset dba_service_name=$3
	
	install_log "INFO" "CHECK_ENV" "Begin to check the privilege of User \"${dba_username}\"."
	
	sqlplus /nolog << EOF > ${TMP}/check_db_user_privs.log
	connect ${dba_username}/${dba_password}@${dba_service_name}
	set pagesize 60
	set linesize 512
	set termout off
	set heading off
	set head off
	set trimspool on
	set feedback off
	
	select granted_role from user_role_privs;
	
	exit;
EOF
	
	if [ -f ${TMP}/check_db_user_privs.log ];then
		typeset error=$(cat ${TMP}/check_db_user_privs.log | grep -E "ERROR|SP2-|ORA-")
	else
		install_log "ERROR" "Excute command sqlplus for ${dba_username} failed!"
		return 1
	fi
	if [ "x${error}" != "x" ]; then
		install_log "ERROR" "CHECK_ENV" "Check user(${dba_username})'s privilege failed.more detail please see ${TMP}/check_db_user_privs.log"
		return 1
	else
		typeset result=$(grep -w 'DBA' ${TMP}/check_db_user_privs.log )
		if [ "X${result}" = "X" ];then
			install_log "ERROR" "CHECK_ENV" "Check db user's privilege failed, the user ${dba_username} doesn't have dba privilege ."
			return 1
		else
			install_log "DEBUG" "CHECK_ENV" "User ${dba_username} has dba privilege,check user(${dba_username})'s privilege successfully"
		fi
	fi
	install_log "INFO" "CHECK_ENV" "Begin to check the privilege of User complete."
}
################################################################################
# Function    : check_db_server
# Description : check database server status whether correct or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_db_server
{
	typeset log_prefix="function check_db_server::"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "Begin to check database server..."
	
	#init db server environment
	init_ora_env "${db_oracle_home}"
	if [ $? -ne 0 ]	
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke init_ora_env ${db_oracle_home} failed."
		install_log "INFO" "CHECK_ENV" "Checking database complete."
		return 1
	fi
	
	add_tns_privilege "${db_oracle_home}"
	if [ $? -ne 0 ]
	then
		((flag=flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke add_tns_privilege \"${db_oracle_home}\" failed."
	fi
	
	read_value "_localNETypeList"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "read_value _localNETypeList failed."
		return 1
	fi
	typeset tmp_name="${RETURN[0]}"
	
	check_onesdp_db_server
	if [ $? -ne 0 ]; then
		return 1
		install_log "ERROR" "CHECK_ENV" "${log_prefix} invoke check_onesdp_db_server failed."
	fi
	
	install_log "INFO" "CHECK_ENV" "${log_prefix} invoke check_onesdp_db_server success."
	install_log "INFO" "CHECK_ENV" "The ne_list is only Onesdp.Not check_lcap_db_server."
	
	install_log "DEBUG" "CHECK_ENV" "Checking database complete."
	return 0
}
################################################################################
# Function    : check_sysdb
# Description : check the database of sys db is enough or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_sysdb
{
	typeset log_prefix="function check_sysdb::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}"
	typeset -i flag=0
	typeset -i rtCode=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to check sysdb information..."
	
	#check the connection status to the db server
	is_tnsping_ok "${db_oracle_sys_type}" "${db_oracle_sys_ip}" "${db_oracle_sys_standby_ip}" "${db_oracle_sys_sid}" \
			"${db_oracle_sys_service_name}" "${db_oracle_sys_net_service_name}" "${db_oracle_sys_port}"
	rtCode=$?
	
	#execute failed
	if [ ${rtCode} -gt 0 -a ${rtCode} -lt ${rt_repair_code} ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_tnsping_ok ${db_oracle_sys_type} ${db_oracle_sys_ip} \
			${db_oracle_sys_standby_ip} ${db_oracle_sys_sid} ${db_oracle_sys_service_name} ${db_oracle_sys_net_service_name} ${db_oracle_sys_port} error!"
		((flag=flag+1))
	#need to repair error
	elif [ ${rtCode} -eq ${rt_repair_code} ]
	then
		#repair tnsping
		add_tns_config "${db_oracle_sys_type}" "${db_oracle_sys_ip}" "${db_oracle_sys_standby_ip}" "${db_oracle_sys_sid}" \
			"${db_oracle_sys_service_name}" "${db_oracle_sys_net_service_name}" "${db_oracle_sys_port}" "${db_oracle_home}"
		
		#reset flag value
		#repair failed,set flag + 1
		if [ $? -ne 0 ]
		then
			((flag=flag+1))
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke add_tns_config \"${db_oracle_sys_type}\" \"${db_oracle_sys_ip}\" \
				\"${db_oracle_sys_standby_ip}\" \"${db_oracle_sys_sid}\" \"${db_oracle_sys_service_name}\" \
				\"${db_oracle_sys_net_service_name}\" \"${db_oracle_sys_port}\" \"${db_oracle_home}\" failed."
		#repair success and then check the tnsping to the db server again.
		else
			install_log "INFO" "CHECK_ENV" "check the connection to the db server again..."
			
			is_tnsping_ok "${db_oracle_sys_type}" "${db_oracle_sys_ip}" "${db_oracle_sys_standby_ip}" "${db_oracle_sys_sid}" \
				"${db_oracle_sys_service_name}" "${db_oracle_sys_net_service_name}" "${db_oracle_sys_port}"
			if [ $? -ne 0 ]
			then
				((flag=flag+1))
			fi
		fi
	fi
	
	#if flag = 0 then continue to checking db space 
	if [ ${flag} -eq 0 ]
	then
		check_sysdb_space
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_sysdb_space failed."
			((flag=flag+1))
		fi
		
		check_sysdb_user
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_sysdb_user failed."
			((flag=flag+1))
		fi
	fi
	
	install_log "DEBUG" "CHECK_ENV" "check sysdb information complete."
	
	if [ ${flag} -gt 0 ]; then
		return 1
	fi
	
}
################################################################################
# Function    : check_userdb
# Description : check the database of userdb is enough or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_userdb
{
	typeset log_prefix="function check_userdb::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}"
	typeset -i flag=0
	typeset -i i=0
	typeset -i rtCode=0
	
	#every cycle unit flag,0 current invoke success and 1 current invoke failed
	typeset -i once_flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to check userdb information..."
	
	while [ ${i} -lt ${userdb_size} ]
	do
		#check the connec status to the user db server
		is_tnsping_ok "${db_oracle_user_type[${i}]}" "${db_oracle_user_ip[${i}]}" "${db_oracle_user_standby_ip[${i}]}" \
			"${db_oracle_user_sid[${i}]}" "${db_oracle_user_service_name[${i}]}" "${db_oracle_user_net_service_name[${i}]}" "${db_oracle_user_port[${i}]}"
		rtCode=$?
		
		#execute failed
		if [ ${rtCode} -gt 0 -a ${rtCode} -lt ${rt_repair_code} ]
		then
			((flag=flag+1))
			once_flag=1
			
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_tnsping_ok ${db_oracle_user_type[${i}]} \
				${db_oracle_user_ip[${i}]} ${db_oracle_user_standby_ip[${i}]} ${db_oracle_user_sid[${i}]} \
				${db_oracle_user_service_name[${i}]} ${db_oracle_user_net_service_name[${i}]} ${db_oracle_user_port[${i}]} error!"
		#need to repair error
		elif [ ${rtCode} -eq ${rt_repair_code} ]
		then
			#execute repair
			add_tns_config "${db_oracle_user_type[${i}]}" "${db_oracle_user_ip[${i}]}" "${db_oracle_user_standby_ip[${i}]}" \
				"${db_oracle_user_sid[${i}]}" "${db_oracle_user_service_name[${i}]}" "${db_oracle_user_net_service_name[${i}]}" \
				"${db_oracle_user_port[${i}]}" "${db_oracle_home}"
			
			#reset flag value
			#repair failed,set flag + 1
			if [ $? -ne 0 ]
			then
				((flag=flag+1))
				once_flag=1
				
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke add_tns_config \"${db_oracle_user_type[${i}]}\" \"${db_oracle_user_ip[${i}]}\" \
					\"${db_oracle_user_standby_ip[${i}]}\" \"${db_oracle_user_sid[${i}]}\" \"${db_oracle_user_service_name[${i}]}\" \
					\"${db_oracle_user_net_service_name[${i}]}\" \"${db_oracle_user_port[${i}]}\" \"${db_oracle_home}\" failed."
			#repair success and then check the tnsping to the db server again.
			else
				install_log "INFO" "CHECK_ENV" "check the connection to the db server again..."
				
				is_tnsping_ok "${db_oracle_user_type[${i}]}" "${db_oracle_user_ip[${i}]}" "${db_oracle_user_standby_ip[${i}]}" \
					"${db_oracle_user_sid[${i}]}" "${db_oracle_user_service_name[${i}]}" "${db_oracle_user_net_service_name[${i}]}" "${db_oracle_user_port[${i}]}"
					
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					once_flag=1
				fi
			fi
		fi
		
		#if flag = 0, then continue to checking db space
		if [ ${once_flag} -eq 0 ]
		then
			check_userdb_space "${i}"
			if [ $? -ne 0 ]; then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_userdb_space ${i} failed."
				((flag=flag+1))
			fi
			
			check_userdb_user "${i}"
			if [ $? -ne 0 ]; then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_userdb_user ${i}failed."
				((flag=flag+1))
			fi
		fi
		
		#reset once_flag = 0
		once_flag=0
		
		#check next user db server
		((i=i+1))
	done
	
	install_log "DEBUG" "CHECK_ENV" "check userdb information complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}

################################################################################
# Function    : check_sysdb_space
# Description : check the sys db space is enough or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_sysdb_space
{
	typeset log_prefix="function check_sys_db::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}"
	
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to check sysdb's tablespace..."
	
	db_space "sysdb" "${db_oracle_sys_net_service_name}" "${db_oracle_sys_dba_username}" "${db_oracle_sys_dba_password}"
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke db_space sysdb ${db_oracle_sys_net_service_name} ${db_oracle_sys_dba_username} failed."
		((flag=flag+1))
	fi
	install_log "DEBUG" "CHECK_ENV" "Checking sysdb's tablespace complete."
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
	
}
################################################################################
# Function    : db_space
# Description : check the database space is enough or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function db_space
{
	typeset log_prefix="function db_space::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."	
	
	if [ $# -ne 4 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix}the input parameter number is incorrect."
		return 1
	fi
	
	typeset dbflag="$1"
	typeset service_name="$2"
	typeset username="$3"
	typeset userpwd="$4"
	
	typeset -i i=0
	typeset sql_script="" 
	typeset sql_tmp=""
	typeset tmp_name=""
	typeset tmp_size=0
	typeset -i result_flag=0
	
	typeset check_str="check_db_space:${dbflag}|${service_name}|${username}|${userpwd}"
	
		
	#check db user's privilege for loading, 
	typeset sqlplus_tail="as sysdba"
	if [ "X${username}" != "Xsys" ];then
		check_db_user_privs "${username}" "${userpwd}" "${service_name}"
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_db_user_privs failed."
			return 1
		fi
		sqlplus_tail=""
	fi
	
	#check whether current db space have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		#the step has been execute
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db space(${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
		
	install_log "DEBUG" "CHECK_ENV" "begin to query [username=${username},userpwd=******,net_service_name=${service_name}] tablespace information..."
	
	#get tablespace info	
	cfg_get_sec_value "${env_std_cfg}" "${dbflag}"
	typeset rt=$?
	if [ ${rt} -ne 0 ]; then
		#if the config file was not contain the segment info,that means don't check the dbspace
		if [ ${rt} -eq ${ERR_CFG_FILE_SEC_NOT_EXIST} ]
		then
			install_log "INFO" "CHECK_ENV" "The segment of ${dbflag} was not contained in ${env_std_cfg}, so do not check the dbspace."
			return 0
		else
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke cfg_get_sec_value ${env_std_cfg} ${dbflag} error."
			install_log "ERROR" "CHECK_ENV" "Getting tablespace size require info failed."
			install_log "DEBUG" "CHECK_ENV" "query tablespace information complete."
			return 1
		fi
	fi
	
	typeset tablespace_count="${RETNUM}"
	
	#get tablespae name and size from config file
	while [ ${i} -lt ${tablespace_count} ]
	do	
		#all the tablespace name convert to capital letter
		tmp_name=`echo "${RETURN[${i}]}" | ${AWK} -F= '{print $1}' | tr "[a-z]" "[A-Z]"` 
		tmp_size=`echo "${RETURN[${i}]}" | ${AWK} -F= '{print $2}'`
		
		if [ ${i} -eq 0 ]; then
			sql_tmp="'${tmp_name}'"
		else
			sql_tmp="${sql_tmp},'${tmp_name}'"
		fi
		
		typeset tablespace_name[${i}]="${tmp_name}"
		typeset tablespace_size[${i}]="${tmp_size}"
		
		((i=i+1))
	done
	
	typeset tmp_log="${TMP}/space_tmp_log.log"
	
	#query dba_free_space,get tablespae size
	#sql_script="select tablespace_name || '+' || sum(BYTES) from dba_free_space where tablespace_name in (${sql_tmp}) group by tablespace_name;"
	sql_script="select e1.tablespace_name || '+' ||
       to_char(f1.total_space - e1.used_space) freespace
  from (select c1.tablespace_name, sum(d1.bytes - c1.free_bytes) used_space
          from (select tablespace_name, file_id, sum(bytes) free_bytes
                  from dba_free_space
                 group by tablespace_name, file_id) c1,
               dba_data_files d1
         where c1.tablespace_name = d1.tablespace_name
           and c1.file_id = d1.file_id
         group by c1.tablespace_name) e1,
       (select tablespace_name,
               sum(case
                     when autoextensible = 'YES' then
                      maxbytes
                     else
                      bytes
                   end) total_space
          from dba_data_files
         group by tablespace_name) f1
 where e1.tablespace_name = f1.tablespace_name
    and e1.tablespace_name in (${sql_tmp})
 union   
 select g1.tablespace_name || '+' || g1.free_space from dba_temp_free_space g1;"
	
	sqlplus /nolog << EOF > ${tmp_log}
	connect ${username}/${userpwd}@${service_name} ${sqlplus_tail}
	set pagesize 60
	set linesize 512
	set termout off
	set heading off
	set head off
	set trimspool on
	set feedback off
	
	${sql_script}
	
	exit;
EOF
	
	
	#check result
	typeset error_tmp=`${GREP} "ERROR" "${tmp_log}"`
	if [ "x${error_tmp}" != "x" ]; then
		((result_flag=result_flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} execute ${sql_script} failed.the reason is `cat ${tmp_log}`"
		install_log "ERROR" "CHECK_ENV" "query table space[username=${username},userpwd=******,net_service_name=${service_name}] failed.the execute results is `cat ${tmp_log}`"
		install_log "DEBUG" "CHECK_ENV" "query tablespace information complete."
	else
		i=0
	  	while [ ${i} -lt ${tablespace_count} ]
	  	do
	  		tmp_name="${tablespace_name[${i}]}"
	  		tmp_size="${tablespace_size[${i}]}"
	  		
	  		((tmp_size=${tmp_size}*1024*1024))
	  		install_log "INFO" "CHECK_ENV" "The ${tmp_name} require free size is ${tmp_size}."
	  		
	  		typeset tmp_num=`${GREP} "^${tmp_name}+" "${tmp_log}" | ${AWK} -F+ '{print $2}'`
	  		
	  		if [ "x${tmp_num}" != "x" ]
	  		then
		  		install_log "INFO" "CHECK_ENV" "The ${tmp_name} free size is ${tmp_num}."
		  		
		  		if [ ${tmp_num} -lt ${tmp_size} ]; then
		  			install_log "ERROR" "CHECK_ENV" "The table space:${tmp_name} free size(${tmp_num}) is too small,require dbspace:${tmp_size}."
		  			((result_flag=result_flag+1))
		  		fi
		  	else
		  		install_log "ERROR" "CHECK_ENV" "The ${tmp_name} was not found in the db server."
		  		((result_flag=result_flag+1))
		  	fi
	  		((i=i+1))
	  	done
	fi
 
  	if [ ${result_flag} -gt 0 ]; then
  		#once execute sql,append information to ${db_temp_file},the value of last filed of '|' is the execute result status,0 is success and 1 is failed.
		echo "${check_str}|1" >> ${db_temp_file}
		
  		rm -rf "${tmp_log}"
  		install_log "DEBUG" "CHECK_ENV" "query tablespace information complete."
  		return 1
  	else
  		#append execute sql
  		echo "${check_str}|0" >> ${db_temp_file}
  		install_log "INFO" "CHECK_ENV" "query tablespace[username=${username},userpwd=******,net_service_name=${service_name}] information is OK."
  	fi
  	
  	install_log "DEBUG" "CHECK_ENV" "query tablespace information complete."
  	
  	#delete temp file
  	rm -rf "${tmp_log}"

}

################################################################################
# Function    : is_db_user_exit
# Description : check the user of oracle is exist or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function is_db_user_exit
{
	
	typeset log_prefix="function is_db_user_exit::"
	
	if [ $# -ne 4 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix}the input parameter number is incorrect."
		return 1
	fi
	
	typeset service_name="$1"
	typeset dbaname="$2"
	typeset dbapwd="$3"
	typeset username="$4"
	
	typeset db_user_tmp_log="${TMP}/dbuser_tmp_log.log"
	
	typeset name=`echo "${username}" | tr "[a-z]" "[A-Z]"`
	
	typeset sql_script="select 'AAA' || count(*) from all_users where USERNAME='$name';"
	
	typeset check_str="check_db_user:${service_name}|${dbaname}|${dbapwd}|${username}"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db user(${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
	
	if [ "X${dbaname}" = "Xsys" ];then
		typeset sql_tail="as sysdba"
	else
		typeset sql_tail=""
	fi
	sqlplus /nolog << EOF > ${db_user_tmp_log}
	connect ${dbaname}/${dbapwd}@${service_name} ${sql_tail}
	set pagesize 60
	set linesize 512
	set termout off
	set heading off
	set head off
	set trimspool on
	set feedback off
	
	${sql_script}
	
	exit;
EOF
	
    #check resut
    typeset result_info=`${GREP} "AAA" "${db_user_tmp_log}"`
    
    #the user has already exist
    if [ "x${result_info}" != "x" -a "${result_info}" != "AAA0" ]; then
    	install_log "ERROR" "CHECK_ENV" "oracle user(${username}) is already exist."
    	rm -rf "${db_user_tmp_log}"
    	#once execute,append information to the ${db_temp_file}
    	echo "${check_str}|1" >> ${db_temp_file}
    	return 1
    else
    	install_log "INFO" "CHECK_ENV" "check oracle user(${username}) is OK."
    	#once execute,append information to the ${db_temp_file}
    	echo "${check_str}|0" >> ${db_temp_file}
    fi
    
    #delete temp file
    rm -rf "${db_user_tmp_log}"
}
#########################################################################
# name	:	get_db_info
# describe:	get db configuration from config.properties
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function get_db_info
{
	typeset log_prefix="function get_db_info::"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to initial dababase config parameters..."
	
	#initial the value of is_db_server flag
	get_db_server_flag
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_db_server_flag error."
		((flag=flag+1))
	fi
	
	#all of the machine have db server configuration,so first initial these global variable
	init_db_server_info
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke init_db_server_info error."
		((flag=flag+1))
	fi
	
	install_log "DEBUG" "CHECK_ENV" "initial dababase config parameters complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# name	:	init_ora_env
# describe:	initial the oracle environment,export oracle variable
# parameter list: null
# input	  : $1 oracle_home
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function init_ora_env
{
	typeset log_prefix="function init_ora_env::"
	
	typeset -i flag=0
	
	typeset check_str="init_ora_env:$1"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the database environment(${check_str}) has been initialied."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
	
	install_log "DEBUG" "CHECK_ENV" "begin to initial oracle environment variable in current user..."
	if [ $# -ne 1 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input parameters incorrect!"
		install_log "ERROR" "CHECK_ENV" "Initializing oracle environment failed!"
		((flag=flag+1))
	else
		typeset ora_home="$1"
		
		export ORACLE_HOME="${ora_home}"
		export PATH="${PATH}:${ORACLE_HOME}/bin"
		
		install_log "INFO" "CHECK_ENV" "initial oracle environment OK."
	fi
	
	install_log "DEBUG" "CHECK_ENV" "initial oracle environment complete."
	
	if [ ${flag} -gt 0 ]
	then
		#once execute,append information to the ${db_temp_file}
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	else
		#once execute,append information to the ${db_temp_file}
		echo "${check_str}|0" >> ${db_temp_file}
	fi
}
################################################################################
# name	:	init_db_server_info
# describe:	initial the global db server configuration
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function init_db_server_info
{
	typeset log_prefix="function init_db_server_info::"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to initial database server information..."
	
	get_oracle_home
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_home error ."
		install_log "ERROR" "CHECK_ENV" "Getting db_oracle_home failed."
		((flag=flag+1))
	fi
	db_oracle_home="${RETURN[0]}"
	
	init_db_server_sys_info
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke init_db_server_sys_info error ."
		((flag=flag+1))
	fi
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# name	:	init_db_server_sys_info
# describe:	initial the sys db server configuration
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function init_db_server_sys_info
{
	typeset log_prefix="function init_db_server_sys_info::"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to initial database server sys information..."
		
    read_value "oracle_server_type"
    if [ $? -ne 0 ]
    then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_type error ."
        install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_type failed."
        ((flag=flag+1))
    fi
    db_oracle_sys_type="${RETURN[0]}"
    
    read_value "oracle_server_ip" "iDeploy_True"
    if [ $? -ne 0 ]
    then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_ip error ."
        install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_ip failed."
        ((flag=flag+1))
    fi
    db_oracle_sys_ip="${RETURN[0]}"
    
    if [ ${db_oracle_sys_type} = "RAC" ];then
        read_value "oracle_server_standby_ip.size" 
        if [ $? -ne 0 ]
        then
            install_log "DEBUG" "CHECK_ENV" "${log_prefix} read oracle_server_standby_ip.size error ."
            install_log "ERROR" "CHECK_ENV" "Getting oracle_server_standby_ip.size failed."
            ((flag=flag+1))
        fi
        
        oracle_server_ip_size="${RETURN[0]}"
        typeset ip_index=0
        while [ $ip_index -lt $oracle_server_ip_size ]
        do 
            read_value "oracle_server_standby_ip.${ip_index}" 
            if [ $? -ne 0 ]
            then
                install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_standby_ip error ."
                install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_standby_ip failed."
                ((flag=flag+1))
            fi
            db_oracle_sys_standby_ip[$ip_index]="${RETURN[0]}"
            ((ip_index=ip_index+1))
        done 
    else
        read_value "oracle_server_sid" 
        if [ $? -ne 0 ]
        then
            install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_sid error ."
            install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_sid failed."
            ((flag=flag+1))
        fi
        db_oracle_sys_sid="${RETURN[0]}"  
    fi
    
    read_value "oracle_server_port"
    if [ $? -ne 0 ]
    then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_port error ."
        install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_port failed."
        ((flag=flag+1))
    fi
    db_oracle_sys_port="${RETURN[0]}"
    
    read_value "oracle_dba_username"
    if [ $? -ne 0 ]
    then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_dba_username error ."
        install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_dba_username failed."
        ((flag=flag+1))
    fi
    db_oracle_sys_dba_username="${RETURN[0]}"
    
    read_value "oracle_dba_password"
    if [ $? -ne 0 ]
    then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_sys_dba_password error ."
        install_log "ERROR" "CHECK_ENV" "Getting db_oracle_sys_dba_password failed."
        ((flag=flag+1))
    fi
    pwd_tmp="${RETURN[0]}"
    decodePwd "${pwd_tmp}"
    if [ $? -ne 0 ]; then
        install_log "ERROR" "CHECK_ENV" "decode ${pwd_tmp} failed."
        return 1
    fi
    db_oracle_sys_dba_password="${RETURN[0]}"

	
	install_log "DEBUG" "CHECK_ENV" "initial database server sys information complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# name	:	init_db_server_maintenancedb_info
# describe:	initial the maintenancedb db server configuration
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function init_db_server_maintenancedb_info
{
	typeset log_prefix="function init_db_server_maintenancedb_info::"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to initial database server maintenancedb information..."

	read_value "maintenancedb.size"
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.size error ."
		install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.size failed."
		((flag=flag+1))
	fi
	mtdb_num="${RETURN[0]}"	
	
	typeset index=0
	while [ $index -lt $mtdb_num ]
	do
		read_value "db_oracle_sys_type"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_type error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_type failed."
			((flag=flag+1))
		fi
		db_oracle_mt_type[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_ip"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_ip error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_ip failed."
			((flag=flag+1))
		fi
		db_oracle_mt_ip[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_standby_ip" "iDeploy_True"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_standby_ip error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_standby_ip failed."
			((flag=flag+1))
		fi
		db_oracle_mt_standby_ip[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_sid" "iDeploy_True"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_sid error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_sid failed."
			((flag=flag+1))
		fi
		db_oracle_mt_sid[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_service_name" "iDeploy_True"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_service_name error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_service_name failed."
			((flag=flag+1))
		fi
		db_oracle_mt_service_name[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_net_service_name"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_net_service_name error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_net_service_name failed."
			((flag=flag+1))
		fi
		db_oracle_mt_net_service_name[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_port"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_port error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_port failed."
			((flag=flag+1))
		fi
		db_oracle_mt_port[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_dba_username"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_dba_username error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_dba_username failed."
			((flag=flag+1))
		fi
		db_oracle_mt_dba_username[$index]="${RETURN[0]}"
		
		read_value "db_oracle_sys_dba_password"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_dba_password error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_dba_password failed."
			((flag=flag+1))
		fi
		maintenancedb_dba_pwd="${RETURN[0]}"
		decodePwd "${maintenancedb_dba_pwd}"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "CHECK_ENV" "decode ${maintenancedb_dba_pwd} failed."
			return 1
		fi	
		db_oracle_mt_dba_password[$index]="${RETURN[0]}"
		
		read_value "maintenancedb.$index.db_oracle_maintenance_username"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_username error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_username failed."
			((flag=flag+1))
		fi
		db_oracle_mt_username[$index]="${RETURN[0]}"
		
		read_value "maintenancedb.$index.db_oracle_maintenance_password"
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} read maintenancedb.$index.db_oracle_maintenance_password error ."
			install_log "ERROR" "CHECK_ENV" "Getting maintenancedb.$index.db_oracle_maintenance_password failed."
			((flag=flag+1))
		fi
		pwd_tmp="${RETURN[0]}"
		decodePwd "${pwd_tmp}"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "CHECK_ENV" "decode ${pwd_tmp} failed."
			return 1
		fi	
		db_oracle_mt_password[$index]="${RETURN[0]}"
		
		((index=index+1))
	done
	
	get_oracle_home
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} read db_oracle_home error ."
		install_log "ERROR" "CHECK_ENV" "Getting db_oracle_home failed."
		((flag=flag+1))
	fi
	db_mt_oracle_home="${RETURN[0]}"

	install_log "DEBUG" "CHECK_ENV" "initial database server maintenancedb information complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}
################################################################################
# name	:	get_db_server_flag
# describe:	check current machine whether install db server
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function get_db_server_flag
{	
	return 0
	#db_server flag:0 false 1 true
	typeset log_prefix="function get_db_server_flag::"
	typeset -i comp_pos=1
	
	install_log "DEBUG" "CHECK_ENV" "get db server flag..."
	
	if [ "x${comp_arr[0]}" = "x" ]
	then
		get_comp_array
		
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_comp_array error !"
			install_log "ERROR" "CHECK_ENV" "get db server flag failed."
			return 1
		fi
	fi
	
	#check whether current machine will be installed db component
	while [ ${comp_pos} -le ${comp_arr[0]} ]
	do
		if [ "db" = "${comp_arr[${comp_pos}]}" -o "billdb" = "${comp_arr[${comp_pos}]}" ]
		then
			is_db_server=1
			break
		fi
		((comp_pos=comp_pos+1))
	done
	
	if [ ${is_db_server} -eq 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "current task does not contain db subcomponent."
	else
		install_log "DEBUG" "CHECK_ENV" "current task contains db subcomponent."
	fi
}
################################################################################
# name	:	check_db_client
# describe:	check the database client connect stutas to the server
# parameter list: null
# input	  : null
# output  : null
# rerurn  : null
# invoker : main
################################################################################
function check_db_client
{
	typeset log_prefix="function check_db_client::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
	
	#get db client string
	typeset segment_name="COMPONENT-ORA-REF"
	typeset key="usedb"
	
	typeset -i db_index=0
	typeset -i db_count=0
	
	typeset -i comp_index=1
	
	typeset db_prefix=""
	typeset ne_name=""
	typeset ne_index=""
	
	typeset -i flag=0
	typeset -i j=0
	typeset -i is_db_exist=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to check database client..."
	
	#get the component list of db client config
	_get_ne_rela_config "${segment_name}" "${key}"
	
	if [ $? -ne 0 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke _get_ne_rela_config ${segment_name} ${key} error!"
		install_log "ERROR" "CHECK_ENV" "Getting the component list of db client config failed."
		install_log "DEBUG" "CHECK_ENV" "Checking database client complete."
		return 1
	fi
	
	db_count="${RETNUM}"
	while [ ${db_index} -lt ${db_count} ]
	do
		typeset db_arr[${db_index}]="${RETURN[${db_index}]}"
		((db_index=db_index+1))
	done
	
	#reset db_index = 0
	db_index=0
	
	#cycle get the db subcomponent connection to the db server
	while [ ${db_index} -lt ${db_count} ]
	do
		#cycle get the component,check the db client subComponent connection to db server
		while [ ${comp_index} -le ${comp_arr[0]} ]
		do
			#reset variable
			j=0
			is_db_exist=0
			
			#get the collection of current component
			get_subComp_by_component "${comp_arr[${comp_index}]}"
			
			if [ $? -ne 0 ]
			then
				install_log "DEBUG" "${log_prefix} invoke get_subComp_by_component ${comp_arr[${comp_index}]} error!"
				install_log "ERROR" "Getting the subcomponent configuration fail by component(${comp_arr[${comp_index}]})."
				((flag=flag+1))
				#turn to check next component
				((comp_index=comp_index+1))
				continue
			fi
			
			#check the subcomponent whether in the component
			while [ ${j} -lt ${RETNUM} ]
			do
				if [ "x${db_arr[${db_index}]}" = "x${RETURN[${j}]}" ]
				then
					is_db_exist=1
					#turn to check next component
					break
				fi
				((j=j+1))
			done
			
			#if db subcomponent not exist in the component,then turn to check next component
			if [ ${is_db_exist} -eq 0 ]
			then
				((comp_index=comp_index+1))
				continue
			fi
			
			#check the subcomponent whether have prefix
			get_subcomp_prefix "${db_arr[${db_index}]}" "${comp_arr[${comp_index}]}"
			
			#the db subcomponent is not contained in the component
			if [ $? -ne 0 ]
			then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_subcomp_prefix ${db_arr[${db_index}]} ${comp_arr[${comp_index}]} error!"
				install_log "ERROR" "CHECK_ENV" "Getting subcomponent ${db_arr[${db_index}]} prefix config failed."
				((flag=flag+1))
				#turn to check next component
				((comp_index=comp_index+1))
				continue
			fi
			
			#if the db subcomponent was belonged more than one component,then need add the prefix
			if [ "x${RETURN[0]}" != "x" ]
			then
				db_prefix=${RETURN[0]}
			fi
			
			#get ne name of current component
			get_ne_by_comp_id "${db_arr[${db_index}]}" "${db_prefix}"
			
			if [ $? -ne 0 ]
			then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_ne_by_comp_id ${comp_arr[${comp_index}]} ${db_prefix} error !"
				install_log "ERROR" "CHECK_ENV" "Can not get the NE name of component ${comp_arr[${comp_index}]} !"
				((flag=flag+1))
				#turn to check next component
				((comp_index=comp_index+1))
				continue
			fi
			
			ne_name="${RETURN[0]}"
			
			#get ne index of current machine
			get_ne_index "${ne_name}"
			
			if [ $? -ne 0 ]
			then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_ne_index ${ne_name} error !"
				install_log "ERROR" "CHECK_ENV" "Can not get the NE index number of current machine !"
				((flag=flag+1))
				#turn to check next component
				((comp_index=comp_index+1))
				continue
			fi
			
			ne_index=${RETURN[0]}
			
			######## A84D13562 begin, by yinjiajun 2009-05-21
			#check oracle client nls_lang environment value
			#check_db_lang
			#if [ $? -ne 0 ]
			#then
			#	((flag=flag+1))
			#fi
			######## A84D13562 end

			#the enip subcomponent only be checked in center node,other node do not check the db connection.
			if [ "x${db_arr[${db_index}]}" = "xenip" ]
			then
				check_enip_client "${db_prefix}" "${ne_index}"
				
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_enip_client ${db_prefix} ${ne_index} error!"
				fi
				#the enip component only one in current ne structure,so do not need to check next component and check the next db subcomponent directly
				break
			elif [ "x${db_arr[${db_index}]}" = "xcbe" ]
			then
				check_cbe_client "${db_prefix}" "${ne_index}"
				
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_cbe_client ${db_prefix} ${ne_index} error!"
				fi
				#the cbe component only one in current ne structure,so do not need to check next component and check the next db subcomponent directly
				break
			elif [ "x${db_arr[${db_index}]}" = "xslccserver" ]
			then
				check_slcc_client "${db_prefix}" "${ne_index}"
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_cbe_client ${db_prefix} ${ne_index} error!"
				fi
				#the cbe component only one in current ne structure,so do not need to check next component and check the next db subcomponent directly
				break	
			elif [ "x${db_arr[${db_index}]}" = "xcgw" ]
			then
				check_cgw_client "${db_prefix}" "${ne_index}"
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_cgw_client ${db_prefix} ${ne_index} error!"
				fi
				#the cbe component only one in current ne structure,so do not need to check next component and check the next db subcomponent directly
				break	
			elif [ "x${db_arr[${db_index}]}" = "xbillconvertor" ]
			then
				check_billconvertor_client "${db_prefix}" "${ne_index}"
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_billconvertor_client ${db_prefix} ${ne_index} error!"
				fi
				#the cbe component only one in current ne structure,so do not need to check next component and check the next db subcomponent directly
				break				
			else
				check_other_client "${db_prefix}" "${db_arr[${db_index}]}"
				
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_other_client ${db_prefix} ${db_arr[${db_index}]} error!"
				fi
				
				#check special db connection of subcomponent to db server first
				#Note:the step must be executed behind check_other_client step,because above step has already initial the oracle environment variable
				check_special_client "${db_prefix}" "${db_arr[${db_index}]}"
				if [ $? -ne 0 ]
				then
					((flag=flag+1))
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_special_client ${db_prefix} ${ne_index} ${db_arr[${db_index}]} error!"
				fi 
				
				#maybe other component contain current subComponent,turn to next component
				((comp_index=comp_index+1))
			fi
		done
		
		#reset comp_index = 1
		comp_index=1
		
		((db_index=db_index+1))
	done
	
	install_log "DEBUG" "CHECK_ENV" "Checking database client complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}

################################################################################
# name	:	is_tnsping_ok
# describe:	check the database client connect stutas to the server
# parameter list: null
# input	  : $1 db_type	[Single|RAC|No-RAC]
#			$2 db_ip	
#			$3 db_standby_ip
#			$4 db_sid
#			$5 db_service_name
#			$6 db_net_service_name
#			$7 db_port
# output  : null
# rerurn  : 0 success 1 fail -1 need to repair
# invoker : main
################################################################################
function is_tnsping_ok
{
	typeset log_prefix="function is_tnsping_ok::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}"
	
	#check the input parameter number
	if [ $# -ne 7 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input number is incorrect!"
		return 1
	fi
	
	typeset db_type="$1"
	typeset db_ip="$2"
	typeset db_standby_ip="$3"
	typeset db_sid="$4"
	typeset db_service_name="$5"
	typeset db_net_service_name="$6"
	typeset db_port="$7"
	
	typeset host_key="HOST"
	typeset port_key="PORT"
	typeset server_name_key="SERVICE_NAME"
	typeset sid_key="SID"
	
	typeset tmp_result_file="${TMP}/tmp_result.txt"
	
	typeset -i flag=0
	typeset -i rtCode=0
	
	#dsdp_oracle_ip's alias.when Single or RAC form the host_name is localhost ip alias,
	#and No-RAC form the host_name is float ip alias
	#typeset host_name=`${GREP} "^[ \t]*${db_ip}" /etc/hosts | ${AWK} '{print $2}'`
	
	#dsdp_oracle_standby_ip's alias.the value only be used in RAC form and the value is
	#other oarcle ne ip's alias
	#if [ "x${db_standby_ip}" != "x" ]
	#then
	#	typeset standby_name=`${GREP} "^[ \t]*${db_standby_ip}" /etc/hosts | ${AWK} '{print $2}'`
	#else
	#	typeset standby_name=""
	#fi
	
	typeset check_str="check_tnsping:${db_net_service_name}"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the tnsping(${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			#if the resultCode = ${rt_repair_code},that means the tns configuration is not exist.when the config is repaired,
			#the tnsping command must allow to execute.
			if [ ${resultCode} -ne ${rt_repair_code} ]
			then
				return ${resultCode}
			fi
		fi
	fi
	
	install_log "DEBUG" "CHECK_ENV" "begin to check tnsping ${db_net_service_name} information..."
	
	#execute tnsping command
	execute_tnsping "${db_net_service_name}" "${tmp_result_file}"
	
	#tnsping ok,parse the oracle db config
	if [ $? -eq 0 ]
	then
		#parse the oracle config is correct or not
		#first convert the string to capital letter
		typeset config_line=`${GREP} -i "Attempting to contact" ${tmp_result_file} | tr "[a-z]" "[A-Z]" `
		
		parse_tns_config "$@" "${config_line}"
		if [ $? -ne 0 ]
		then
			((flag=flag+1))
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invok parse_tns_config failed."
		fi
	else
		#execute failed and set flag value
		((flag=flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke execute_tnsping ${db_net_service_name} ${tmp_result_file} failed."
		
		#if the tnsping exception can be repaired,then reapir it.
		parse_failure_file "${tmp_result_file}" "1" "${db_net_service_name}"
		rtCode=$?
		
		#invoke parse_failure_file failed
		if [ ${rtCode} -gt 0  -a ${rtCode} -lt ${rt_repair_code} ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke parse_failure_file ${tmp_result_file} failed."
		#tnsping error need to repair
		elif [ ${rtCode} -eq ${rt_repair_code} ]
		then
			#reset return flag = -1
			flag=${rtCode}
		fi
	fi
	
	#delete the temp script and result file
	rm -f ${tmp_result_file}
	
	install_log "DEBUG" "CHECK_ENV" "check tnsping ${db_net_service_name} complete."

	# if flag exists, delete it first
	sed "/^${check_str}|/d" "${db_temp_file}" > "${db_temp_file}_$$"
	mv -f "${db_temp_file}_$$" "${db_temp_file}"
	
	#above invoke execute failed
	if [ ${flag} -gt 0 -a ${flag} -lt ${rt_repair_code} ] 
	then
		#once execute,append tnsping to the file ${db_temp_file}
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	#the tnsping error need to repair
	elif [ ${flag} -eq ${rt_repair_code} ]
	then
		#once execute,append tnsping to the file ${db_temp_file}
		echo "${check_str}|${flag}" >> ${db_temp_file}
		return ${flag}
	else
		#once execute,append tnsping to the file ${db_temp_file}
		echo "${check_str}|0" >> ${db_temp_file}
	fi
}

################################################################################
# name	:	execute_tnsping
# describe:	execute tnsping command
# parameter list: null
# input	  : $1 net_service_name or sid
#			$2 redirect_file
# output  : null
# rerurn  : 0 success 1 fail
# invoker : main
################################################################################
function execute_tnsping
{
	typeset log_prefix="function execute_tnsping::"
	typeset net_service_name="$1"
	typeset redirect_file="$2"
	typeset -i flag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to execute \"tnsping ${net_service_name}\" command..."
	
	if [ "x${net_service_name}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input first parameter \"net_service_name\" is null string."
		install_log "ERROR" "CHECK_ENV" "the net_service_name is null string."
		install_log "DEBUG" "CHECK_ENV" "tnsping command execute complete."
		return 1
	fi
	
	if [ "x${redirect_file}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input second parameter \"redirect_file\" is null string."
		install_log "ERROR" "CHECK_ENV" "the redirect_file is null string."
		install_log "DEBUG" "CHECK_ENV" "tnsping command execute complete."
		return 1
	fi
	
	#check the connect statut to the db server
	tnsping "${net_service_name}" > "${redirect_file}" 2>&1
	if [ $? -ne 0 ]
	then
		((flag=flag+1))
		install_log "INFO" "CHECK_ENV" "execute tnsping ${net_service_name} command failed."
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke tnsping ${net_service_name} failure!the failure reason is `cat ${redirect_file}`"
	else
		install_log "INFO" "CHECK_ENV" "execute \"tnsping ${net_service_name}\" command success."
	fi
	
	install_log "DEBUG" "CHECK_ENV" "tnsping command execute complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}

################################################################################
# name	:	parse_tns_config
# describe:	parse the tnsping result string,analyse the config whether correct
#			with the ideploy web config
# parameter list: null
# input	  : $1 db_type	[Single|RAC|No-RAC]
#			$2 db_ip	
#			$3 db_standby_ip
#			$4 db_sid
#			$5 db_service_name
#			$6 db_net_service_name
#			$7 db_port
#			$8 host_name
#			$9 standby_name
#			$10 parse_string
# output  : null
# rerurn  : 0 success 1 fail
# invoker : main
################################################################################
function parse_tns_config
{
	typeset log_prefix="function parse_tns_config::"
	 
	typeset host_key="HOST"
	typeset port_key="PORT"
	typeset server_name_key="SERVICE_NAME"
	typeset sid_key="SID"
	
	install_log "DEBUG" "CHECK_ENV" "begin to parse tnsping result..."
	
	#check the input parameter number
	if [ $# -ne 8 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input number is incorrect!"
		return 1
	fi
	
	typeset db_type="$1"
	typeset db_ip="$2"
	typeset db_standby_ip="$3"
	typeset -u db_sid="$4"
	typeset -u db_service_name="$5"
	typeset -u db_net_service_name="$6"
	typeset -u db_port="$7"
	#typeset -u host_name="$8"
	#typeset -u standby_name="$8"
	 
	#input parameter left one position,purpose get the last parameter
	shift 1
	
	typeset config_line="$7"
	
	typeset -i i=0
	typeset -i flag=0
	
	typeset is_service_name_config=`echo "${config_line}" | ${GREP} "${server_name_key}"`
	typeset is_sid_config=`echo "${config_line}" | ${GREP} "${sid_key}"`

	#get HOST attribute value
	get_tns_config_by_key "${host_key}" "${config_line}"
	
	if [ $? -ne 0 ]
	then
		((flag=flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke parse_tns_config ${host_key} ${config_line} error!"
		install_log "ERROR" "CHECK_ENV" "Checking ${db_net_service_name} config failed!"
	else
		if [ "x${db_type}" = "xSingle" -o "x${db_type}" = "xNo-RAC" ]
		then
			#Single or No-RAC only get the second filed of parse string
			typeset host_info=`echo "${RETURN[0]}" | ${AWK} -F\| '{print $2}'`
			
			#the host attribute must the same as ip address or ip alias
			if [ "x${host_info}" != "x${db_ip}" ]
			then
				((flag=flag+1))
				install_log "ERROR" "CHECK_ENV" "The db tnanames.ora host attribute config incorrect! the require value is ${db_ip},in fact the real value is ${host_info}"
			fi
		elif [ "x${db_type}" = "xRAC" ]
		then
			#RAC have more than one host address
			typeset host_num=`echo "${RETURN[0]}" | ${AWK} -F\| '{print $1}'`
			typeset -i field_idx=2
			#cycle check the host attribute whether correct
			while [ ${i} -lt ${host_num} ]
			do
				typeset host_info=`echo "${RETURN[0]}" | ${AWK} -F\| -vidx=${field_idx} '{print $idx}'`
				
				if [ "x${host_info}" != "x${db_ip}" -a "x${host_info}" != "x${db_standby_ip}" ]
				then
					((flag=flag+1))
					install_log "ERROR" "CHECK_ENV" "the db tnsnames.ora host attribute config incorrect!the require value is ${db_ip} and ${db_standby_ip},in fact the real value is ${host_info}"
				fi
				((field_idx=field_idx+1))
				((i=i+1))
			done
		else
			((flag=flag+1))
			install_log "ERROR" "CHECK_ENV" "The db type is incorrect!"
		fi
	fi
	
	#get PORT attribute value
	get_tns_config_by_key "${port_key}" "${config_line}"
	
	if [ $? -ne 0 ]
	then
		((flag=flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke parse_tns_config ${port_key} ${config_line} error!"
		install_log "ERROR" "CHECK_ENV" "Checking ${db_net_service_name} config failed!"
	else
		#Single or No-RAC only get the second filed of parse string
		typeset port_info=`echo "${RETURN[0]}" | ${AWK} -F\| '{print $2}'`
		
		#check db listen port
		if [ "x${db_port}" != "x${port_info}" ]
		then
			((flag=flag+1))
			install_log "ERROR" "CHECK_ENV" "The db tnsnames.ora port attribute config incorrect! the require value is ${db_port},in fact the real value is ${port_info}"
		fi
	fi
	
	if [ "x${is_service_name_config}" != "x" -o "x${is_sid_config}" != "x" ]
	then
		typeset service_name_info=""
		typeset sid_name_info=""
		if [ "x${is_service_name_config}" != "x" ]
		then
			#get SERVICE_NAME attribute value
			get_tns_config_by_key "${server_name_key}" "${config_line}"
			
			if [ $? -ne 0 ]
			then
				((flag=flag+1))
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke parse_tns_config ${server_name_key} ${config_line} error!"
				install_log "ERROR" "CHECK_ENV" "Checking ${db_net_service_name} config failed!"
			else
				service_name_info=`echo "${RETURN[0]}" | ${AWK} -F\| '{print $2}'`
			fi
		fi
		
		if [ "x${is_sid_config}" != "x" ]
		then
			#get SID attribute value
			get_tns_config_by_key "${sid_key}" "${config_line}"
			
			if [ $? -ne 0 ]
			then
				((flag=flag+1))
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke parse_tns_config ${sid_key} ${config_line} error!"
				install_log "ERROR" "CHECK_ENV" "Checking ${db_net_service_name} config failed!"
			else
				sid_name_info=`echo "${RETURN[0]}" | ${AWK} -F\| '{print $2}'`
			fi
		fi
		
		#the RAC form must config service_name key
		if [ "x${db_type}" = "xRAC" ]
		then
			if [ "x${is_service_name_config}" != "x" ]
			then
				if [ "x${service_name_info}" != "x${db_service_name}" ]
				then
					((flag=flag+1))
					install_log "ERROR" "CHECK_ENV" "The db tnsnames.ora service_name attribute config incorrect! the require value is ${db_service_name},in fact the real value is ${service_name_info}"
				fi
			else
				((flag=flag+1))
				install_log "ERROR" "CHECK_ENV" "The tnsnames.ora config must use service_name identity,can't use SID identity."
			fi
		#the No-RAC and Single form must config sid key	
		elif [ "x${db_type}" = "xSingle" -o "x${db_type}" = "xNo-RAC" ]
		then
			if [ "x${is_sid_config}" != "x" ]
			then
				if [ "x${sid_name_info}" != "x${db_sid}" ]
				then
					((flag=flag+1))
					install_log "ERROR" "CHECK_ENV" "The db tnsnames.ora SID attribute config incorrect! the require value is ${db_sid},in fact the real value is ${sid_name_info}"
				fi
			else
				((flag=flag+1))
				install_log "ERROR" "CHECK_ENV" "The tnsnames.ora config must use SID identity, can't use service_name identity."
			fi
		fi
		
		if [ ${flag} -eq 0 ]
		then
			install_log "INFO" "CHECK_ENV" "check ${db_net_service_name} tnsnames.ora config OK."
		fi
	else
		((flag=flag+1))
		install_log "ERROR" "CHECK_ENV" "The db tnsnames.ora config error!"
	fi
	
	install_log "DEBUG" "CHECK_ENV" "parse tnsping result complete."
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}

################################################################################
# name	:	get_tns_config_by_key
# describe:	parse oracle tnsnames.ora configuration, get the value by the key
# parameter list: $1 the key you wanted get the value
#				  $2 the configuration of current sid
# input	  : null
# output  : RETURN[0] the result value of specify key,the form is num|str1|str2|..|strN
#			the "num" is the number of result string.
#			the "strN" is the value 
#
#			for example,the config is 
#			dbsrv=
#				(DESCRIPTION=
#					(ADDRESS_LIST=
#				        (ADDRESS=(PROTOCOL=TCP)(HOST= rac-node1)(PORT=1521))
#				        (ADDRESS=(PROTOCOL=TCP)(HOST= rac-node2)(PORT=1521))
#						(ADDRESS=(PROTOCOL=TCP)(HOST= 10.10.10.10)(PORT=1521))
#				        (FAILOVER=on)
#						(LOAD_BALANCE=on)
#						(CONNECT_DATA=
#							(SERVER=DEDICATED)
#							(SERVICE_NAME=<dbname>)
#						)
#					)
#				)
#
#			invoke parse_tns_file "HOST" ,the result is 3|rac-node1|rac-node2|10.10.10.10
#			invoke parse_tns_file "CONNECT_DATA" ,the result is 1|(SERVER=DEDICATED)(SERVICE_NAME=<dbname>)
# rerurn  : 0 success 1 fail
# invoker : main
################################################################################
function get_tns_config_by_key
{
	typeset log_prefix="function get_tns_config_by_key::"
	
	if [ $# -ne 2 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input parameter number is incorrect !"
		return 1
	fi
	
	if [ "x$1" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the first input parameter is null string !"
		return 1
	fi
	
	if [ "x$2" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the second input parameter is null string !"
		return 1
	fi
	
	typeset key=$1
	typeset parse_str=$2
	typeset result_str=""
	
	result_str=`echo "${parse_str}" | ${GREP} "^[^#]" | ${SED} -n "s#[ \t]##gp" | ${AWK} -vkey=${key} '
		{
			src_str=$0
			key_length = length(key)
			target_pos = 0
			cycle_flag = 1
			left_str=""
			final_str=""
			final_num=0
			
			while (cycle_flag)
			{
				#find the key string position
				target_pos = index(src_str,key)
				
				#can not find the key flag then jump the cycle
				if (target_pos == 0)
				{
					break
				}
				
				#get the left string after cut src string from key
				#for example abckey=value,then the left str is =value
				left_str = substr(src_str,target_pos + key_length)
				
				#get the match value
				temp_str=getValue(left_str)
				
				#can not find the value,jump the cycle
				if (temp_str == "")
				{
					break
				}
				
				final_num = final_num + 1
				
				#combine the final_str,the result string form result1|result2|..|resultN
				final_str = final_str "|" temp_str
				
				#reset the src_str,cut the value string
				src_str = substr(left_str,length(temp_str)+1)
				
			}
			
			#the return string form is final_num|final_str1|final_str2|..|final_strN
			final_str = final_num final_str
			
			print final_str
		}
		#get the value of the key from left string,
		#maybe the left string nest ( and ) symbol,so need find the last single ) then cut 
		function getValue(str)
		{	
			str_length=length(str)
			target_str=""
			
			#cut the str string from first position
			pos=1
			
			#find the ) symbol from left to right. when find the ( symbol,the match_flag + 1
			#when find the ) symbol,the match_flag - 1.so if the match_flag = 0,break the cycle
			match_flag=1
			
			while ( match_flag > 0 )
			{
				singleChar=substr(str,pos,1)
				
				if ( singleChar == "(" )
				{
					match_flag = match_flag + 1
				}
				else if ( singleChar == ")" )
				{
					match_flag = match_flag - 1
				}
				
				#combine the string
				target_str=target_str singleChar
				
				#find the last character 
				if (pos == str_length)
				{
					break
				}
				
				#get next singleChar
				pos = pos + 1
			}
			
			#find the match ) symbol and = symbol,then cut the last ) and first =
			if ( match_flag == 0 )
			{
				#cut = symbol
				target_str = substr(target_str,2)
				
				#cut ) symbol
				target_str = substr(target_str,1,length(target_str)-1)
			}
			#can not find the match string,return null string
			else
			{
				target_str = ""
			}
			
			return target_str
		}'`
	
	RETURN[0]=${result_str}
}

################################################################################
# Function    : check_db_lang
# Description : check the database language is correct or not.
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_db_lang
{
	typeset log_prefix="function check_db_lang::"
	
	typeset -i flag=0
	
	typeset check_str="check_db_lang"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the database lang(${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
	
	install_log "DEBUG" "CHECK_ENV" "begin to check database language value..."
	
	typeset db_lang=`su - oracle -c "env | ${GREP} ^NLS_LANG | ${AWK} -F= '{print \\$2}'"`
	
	if [ "x${db_lang}" != "x" ]
	then
		if [ "x${db_lang}" != "xAMERICAN_AMERICA.AL32UTF8" ]
		then
			install_log "ERROR" "CHECK_ENV" "Checking oracle env NLS_LANG error.Current value is ${db_lang} and the right value is AMERICAN_AMERICA.AL32UTF8."
			((flag=flag+1))
		else
			install_log "INFO" "CHECK_ENV" "db language set OK."
		fi
	else
		install_log "ERROR" "CHECK_ENV" "can not get the oracle user's nls_lang environment value!"
		((flag=flag+1))
	fi
	
	install_log "DEBUG" "CHECK_ENV" "check database language complete."
	
	if [ ${flag} -gt 0 ]
	then
		#once execute,append information to the ${db_temp_file}
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	else
		#once execute,append information to the ${db_temp_file}
		echo "${check_str}|0" >> ${db_temp_file}
	fi
}

################################################################################
# name	:	parse_failure_file
# describe:	parse tnsping command redirect file,find the failure reason.if the
#			TNS-xxx error can be repaired then repair the error.
# parameter list: null
# input	  : $1 redirect_file
#			$2 if_repair 0 don't repair 1 repair
# output  : null
# rerurn  : 0 success 1 fail -1 need to repair
# invoker : main
################################################################################
function parse_failure_file
{
	typeset log_prefix="function parse_failure_file::"
	
	typeset failure_file="$1"
	typeset -i flag=0
	typeset -i rtCode=0
	#default don't reapir exception of tnsping command
	typeset -i is_repair=0
	
	typeset log_level="ERROR"
	
	if [ "x${failure_file}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "the input parameter is null string."
		return 1
	fi
	
	#check failure file whether exist
	if [ ! -f ${failure_file} ]
	then
		install_log "ERROR" "CHECK_ENV" "the failure file ${failure_file} is no exist."
		return 1
	fi
	
	install_log "DEBUG" "CHECK_ENV" "begin to solve the failure file..."
	if [ "x$2" != "x" ]
	then
		is_repair="$2"
		
	fi
	
	typeset net_service="$3"
	
	#delete head space
	typeset failure_reason=`${GREP} "^[ \t]*TNS-" ${failure_file} | ${SED} -n 's/^[ \t]*//p'`
	
	#can't get the failure reason
	if [ "x${failure_reason}" = "x" ]
	then
		((flag=flag+1))
		install_log "ERROR" "CHECK_ENV" "unknown exception of tnsping command result."
	else
		typeset tns_code=`echo ${failure_reason} | ${AWK} -F: '{print $1}'`
		
		#check whether repair the exception
		if [ ${is_repair} -eq 1 ]
		then
			#TNS-03505: Failed to resolve name
			if [ "x${tns_code}" = "xTNS-03505" ]
			then
				log_level="INFO"
			
				#set flag = -1 and notice repair the error
				flag=${rt_repair_code}
			else
				((flag=flag+1))
			fi
		else
			((flag=flag+1))
		fi
		
		install_log "${log_level}" "CHECK_ENV" "the failure reason is \"${failure_reason}\" of execute tnsping command,please check the IP and ORACLE_SID is correct, or network service name[${net_service}] is already occupied.
"
	fi
	
	install_log "DEBUG" "CHECK_ENV" "solve the failure file complete."
	
	#above invoke execute failed
	if [ ${flag} -gt 0 -a ${flag} -lt ${rt_repair_code} ] 
	then
		return 1
	#the tnsping error need to repair
	elif [ ${flag} -eq ${rt_repair_code} ]
	then
		return ${flag}
	fi
}

################################################################################
# name	:	add_tns_config
# describe:	if the net_service_name config not in tnsnames.ora,then add a standard
#			config to the tnsnames.ora
#
#			the Single and no-RAC form is
#				net_servcie_name =
#					(DESCRIPTION =
#    					(ADDRESS = (PROTOCOL = TCP)(HOST = ip)(PORT = port))
#    					(CONNECT_DATA =
#      						(SERVER = DEDICATED)
#      						(SID = sid)
#    					)
#  					)
#			
#			the RAC form is
#				net_service_name =
#				  (DESCRIPTION =
#				    (ADDRESS = (PROTOCOL = TCP)(HOST = ip)(PORT = port))
#				    (ADDRESS = (PROTOCOL = TCP)(HOST = standby_ip)(PORT = port))
#				    (CONNECT_DATA =
#				      (SERVER = DEDICATED)
#				      (SERVICE_NAME = service_name)
#				    )
#				  )
#			Note:the RAC must share a common port.
#
# parameter list: null
# input	  : $1 db_type	[Single|RAC|No-RAC]
#			$2 db_ip	
#			$3 db_standby_ip
#			$4 db_sid
#			$5 db_service_name
#			$6 db_net_service_name
#			$7 db_port
#			$8 oracle_home
# output  : null
# rerurn  : 0 success 1 fail -1 need to repair
# invoker : main
################################################################################
function add_tns_config
{
	typeset log_prefix="function add_tns_config::"
	
	typeset tns_config=""
	
	#check input parameter number
	if [ $# -ne 8 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input parameter number is incorrect."
		return 1
	fi
	
	typeset db_type="$1"
	typeset db_ip="$2"
	typeset db_standby_ip="$3"
	typeset db_sid="$4"
	typeset db_service_name="$5"
	typeset db_net_service_name="$6"
	typeset db_port="$7"
	typeset db_home="$8"
	
	typeset -i flag=0
	typeset tmp_file="/tmp/lock_tns_ora.tmp"
	typeset tmp_tnsnames_file="${TMP}/tnsnames.tmp"
	typeset tnsnames_file=""
	typeset tns_admin_path=`su - oracle -c "env | ${GREP} ^TNS_ADMIN | ${AWK} -F= '{print \\$2}'"`
	
	typeset check_str="add_tns_config:${db_net_service_name}"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the add tns config (${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
	
	#check input parameter whether invalid
	if [ "x${db_type}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_type is null string."
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	else
		if [ "x${db_type}" != "xSingle" -a "x${db_type}" != "xRAC" -a "x${db_type}" != "xNo-RAC" ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_type must be [Single|RAC|No-RAC]."
			echo "${check_str}|1" >> ${db_temp_file}
			return 1
		fi
	fi
	
	if [ "x${db_ip}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_ip is null string"
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	fi
	
	if [ "x${db_standby_ip}" = "x" -a "x${db_type}" = "xRAC" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_standby_ip is null string in RAC mode."
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	fi
	
	if [ "x${db_type}" = "xSingle" -o "x${db_type}" = "xNo-RAC" ]
	then
		if [ "x${db_sid}" = "x" ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_sid is null string."
			echo "${check_str}|1" >> ${db_temp_file}
			return 1
		fi
	elif [ "x${db_type}" = "xRAC" ]
	then
		if [ "x${db_service_name}" = "x" ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_service_name is null string."
			echo "${check_str}|1" >> ${db_temp_file}
			return 1
		fi
	fi
	
	if [ "x${db_net_service_name}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_net_service_name is null string."
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	fi
	
	if [ "x${db_port}" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_port is null string."
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	fi
	
	if [ "x${db_home}" = "x" -a -d ${db_home} ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the db_home is null or not a directory."
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	fi
	
	#first find TNS_ADMIN/tnsnames.ora
	if [ "x${tns_admin_path}" != "" -a -f "${tns_admin_path}/tnsnames.ora" ]
	then
		tnsnames_file="${tns_admin_path}/tnsnames.ora"
		ls ${tns_admin_path} >/dev/null
		if [ $? -ne 0 ];then
			install_log "ERROR" "CHECK_ENV" "${tns_admin_path} is not exists,please check it!!"
			return 1
		fi
	else
		if [ -f "${db_home}/network/admin/tnsnames.ora" ]
		then
			tnsnames_file="${db_home}/network/admin/tnsnames.ora"
		else
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} can't find the tnsnames.ora file,create a new tnsnames.ora file."
			ls ${db_home} >/dev/null
			if [ $? -ne 0 ];then
				install_log "ERROR" "CHECK_ENV" "${db_home} is not exists,please check it!!"
				return 1
			fi
			if [ ! -d "${db_home}/network/admin" ]
			then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} create directory ${db_home}/network/admin."
				su - oracle -c "mkdir -p ${db_home}/network/admin"
			fi
			
			su - oracle -c "touch ${db_home}/network/admin/tnsnames.ora"
			if [ $? -ne 0 ]
			then
				install_log "ERROR" "CHECK_ENV" "create ${db_home}/network/admin/tnsnames.ora failed."
				echo "${check_str}|1" >> ${db_temp_file}
				return 1
			fi
			
			tnsnames_file="${db_home}/network/admin/tnsnames.ora"
		fi
	fi
	
	#maybe multiple process write tns config to tnsnames.ora at the same time.
	#so once any process will write tnsname.ora,it create a /tmp/lock_tns_ora.tmp file for the lock,
	#and then other process find the lock will be wait until the file not exist.
	
	#check whether tmp file exist
	while [ -f ${tmp_file} ]
	do
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the file ${tmp_file} already exist,wait 1 second."
		sleep 1
	done
	
	#create tmp file
	touch ${tmp_file}
	
	install_log "INFO" "CHECK_ENV" "begin to add the oracle tns configuration(${db_net_service_name})..."
	
	
	
	echo "" | ${AWK} -vdbType=${db_type} -vip=${db_ip} -vstandbyIp=${db_standby_ip} -vsid=${db_sid} \
					-vsrvName=${db_service_name} -vnetSrvName=${db_net_service_name} -vport=${db_port} '
					{
						config_str="\n"
						config_str=config_str netSrvName " =" "\n  "
						config_str=config_str "(DESCRIPTION =" "\n    "
						config_str=config_str "(ADDRESS = (PROTOCOL = TCP)(HOST = " ip ")(PORT = " port "))" "\n    "
						if (dbType == "RAC")
						{
							config_str=config_str "(ADDRESS = (PROTOCOL = TCP)(HOST = " standbyIp ")(PORT = " port "))" "\n    "
						}
						config_str=config_str "(CONNECT_DATA =" "\n      "
						config_str=config_str "(SERVER = DEDICATED)" "\n      "
						if (dbType == "RAC")
						{
							config_str=config_str "(SERVICE_NAME = " srvName ")" "\n    "
						}
						else
						{
							config_str=config_str "(SID = " sid ")" "\n    "
						}
						config_str=config_str ")" "\n  "
						config_str=config_str ")" "\n"
						
						printf("%s",config_str)
					}' | tee ${tmp_tnsnames_file}
					
	if [ ! -f ${tmp_tnsnames_file} ]
	then
		((flag=flag+1))
		install_log "ERROR" "CHECK_ENV" "get tns config failed."
	else
		install_log "INFO" "CHECK_ENV" "the tns config is `cat ${tmp_tnsnames_file}` "
		
		#append tns config to tnsnames.ora
		cat ${tmp_tnsnames_file} >> ${tnsnames_file}
		if [ $? -ne 0 ]
		then
			((flag=flag+1))
			install_log "ERROR" "CHECK_ENV" "add tns config failed."
		else
			install_log "INFO" "CHECK_ENV" "add tns config success."
		fi
	fi
	
	#delete lock file and temp file
	rm -rf ${tmp_file}
	rm -rf ${tmp_tnsnames_file}
	
	install_log "INFO" "CHECK_ENV" "add tns configuration complete."
	
	if [ ${flag} -gt 0 ]
	then
		echo "${check_str}|1" >> ${db_temp_file}
		return 1
	else
		echo "${check_str}|0" >> ${db_temp_file}
	fi
}

################################################################################
# Function    : add_tns_privilege
# Description : add popedom 644 to the file of tnsnames.ora
# parameter list:$1 oracle_home
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function add_tns_privilege
{
	typeset log_prefix="function add_tns_privilege::"
	
	if [ "x$1" = "x" ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input parameter is null string."
		return 1
	fi
	
	typeset oracle_home="$1"
	typeset tns_file="${oracle_home}/network/admin/tnsnames.ora"
	
	#next step will create the tnsnames.ora file
	if [ ! -f ${tns_file} ]
	then
		install_log "INFO" "CHECK_ENV" "the ${tns_file} is not exist."
		return 0
	fi
	
	typeset check_str="add_tns_privilege:${tns_file}"
	
	#check whether current db user have been checked
	if [ -f ${db_temp_file} ]
	then
		typeset -i check_num=`grep -w "^${check_str}" ${db_temp_file} | wc -l`
		if [ ${check_num} -gt 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} the add tns popedom (${check_str}) information has been checked."
			#get the execute status of last time
			typeset -i resultCode=`grep -w "^${check_str}" "${db_temp_file}" | awk -F\| '{print $NF}'`
			return ${resultCode}
		fi
	fi
	
	chmod 644 ${tns_file}
	if [ $? -ne 0 ]
	then
		echo "${check_str}|1" >> ${db_temp_file}
		install_log "ERROR" "CHECK_ENV" "add popedom to ${tns_file} failed."
		return 1
	else
		echo "${check_str}|0" >> ${db_temp_file}
		install_log "INFO" "CHECK_ENV" "add 644 popedom to ${tns_file} success."
		return 0
	fi
}

################################################################################
# Function    : check_sysdb_user
# Description : check the user of sys db is exist or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_sysdb_user
{
	typeset log_prefix="function check_sysdb_user::"
	typeset -i dbflag=0
	
	install_log "DEBUG" "CHECK_ENV" "begin to check sysdb's user(${db_oracle_sys_username}) whether exist..."
	
	#check_db_exist
	check_onesdp_db_user 
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_onesdp_db_user failed."
		((dbflag=dbflag+1))
	fi	
	
	typeset create_flag=0
	if [ -f ${TMP}/sysdb_create_flag.cfg ];then
		typeset create_flag_tmp=$(cat ${TMP}/sysdb_create_flag.cfg |  sed '/^[ ]*$/d'| awk -F'=' '{print $2}')
		if [ "X${create_flag_tmp}" = "X2" ];then
			create_flag=1
		fi
	fi
	
	if [ "X${create_flag}" = "X0" ];then
		is_db_user_exit "${db_oracle_sys_net_service_name}" "${db_oracle_sys_dba_username}" "${db_oracle_sys_dba_password}" "${db_oracle_sys_username}"	
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke is_db_user_exit ${db_oracle_sys_net_service_name} ${db_oracle_sys_dba_username} ${db_oracle_sys_dba_password} ${db_oracle_sys_username} error ."  	
			((dbflag=dbflag+1))
		fi	
	fi
	
    install_log "DEBUG" "CHECK_ENV" "check sysdb user complete." 
    
    if [ ${dbflag} -gt 0 ]; then
   		return 1
  	fi
}
################################################################################
# Function    : check_onesdp_db_server
# Description : check the user of lcap db is exist or not
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_onesdp_db_server
{
	install_log "INFO" "CHECK_ENV" "Begin to check Onesdp db server."
	typeset flag=0
	get_net_struc_business_type
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "Getting business type of current net structure failed."
		return 1
	fi
	typeset business_type="${RETURN[0]}"
	
	check_sysdb
	if [ $? -ne 0 ]; then
		((flag=flag+1))
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_sysdb failed."
	fi	
	
	if [ ${flag} -gt 0 ]; then
		return 1
	fi
	
	install_log "INFO" "CHECK_ENV" "End to check Onesdp db server."
	return 0
}
function check_onesdp_db_user
{
    typeset db_user_tmp_log="${TMP}/check_db_user_exist.log"
	#read all of [UP-TABLE] from xxxall_small.ini.
	typeset table=$(sed -n "/^[    ]*\[[   ]*UP-TABLE[  ]*\]/,/^[       ]*\[.*\]*/p" ${IDEPLOY_PKG_PATH}/script/up_small.ini | sed '/^[ ]*$/d' | sed -n '2,$p')
	typeset table_name_list=" "

	for item in $table
	do	
		table_name_list="'${item}',${table_name_list}"
	done
        
	table_name=$(echo ${table_name_list} |sed 's/,$//g')
	typeset sql_script="select 'username=' || count(*) from dba_users where username=upper('${db_oracle_sys_username}');"
	typeset sql_script1="select 'table_count=' || count(*) from dba_tables where owner=upper('${db_oracle_sys_username}') and table_name in (${table_name});"
	
	if [ "X${db_oracle_sys_dba_username}" = "Xsys" ];then
		typeset sql_tail="as sysdba"
	else
		typeset sql_tail=""
	fi

sqlplus /nolog<<EOF > ${db_user_tmp_log}
	connect ${db_oracle_sys_dba_username}/${db_oracle_sys_dba_password}@${db_oracle_sys_net_service_name} ${sql_tail}
	set pagesize 60
	set linesize 512
	set termout off
	set heading off
	set head off
	set trimspool on
	set feedback off
	
	${sql_script} 
	${sql_script1}
	exit;
EOF

    #check resut
	grep "ORA-"  ${db_user_tmp_log} >/dev/null 2>&1
	if [ $? -eq 0 ];then
		install_log "ERROR" "CHECK_ENV" "Run check user and table failed, Please see log ${db_user_tmp_log}"
		return 1
	fi
	
	typeset username_info1=$(grep -v "SQL" ${db_user_tmp_log} | sed '/^[ ]*$/d'| awk -F'=' '{if($1~/username/) print $2}')
	typeset table_info2=$(grep -v "SQL" ${db_user_tmp_log} | sed '/^[ ]*$/d'| awk -F'=' '{if($1~/table_count/) print $2}')
	typeset sysdb_create_flag="${TMP}/sysdb_create_flag.cfg"
	
	if [ -f ${sysdb_create_flag} ];then
		rm -f ${sysdb_create_flag} >/dev/null 2>&1
	fi
	if [ "x${username_info1}" = "x0" ];then
	
		install_log "INFO" "CHECK_ENV" "oracle user(${db_oracle_sys_username}) does not exist."
		echo "sysdb_create_flag=0" > "${sysdb_create_flag}"
	else 
		if [ "x${table_info2}" = "x0" ];then
			#begin to insert ip to onesdp_t_ip_auth
			get_all_ip
			if [ $? -ne 0 ]; then
				install_log "ERROR" "CHECK_ENV" "get all ip list failed."
				return 1
			fi
			typeset ip_list="${RETURN[0]}"
			typeset ip_auth=$(echo ${ip_list}|sed "s#'##g")
			
			create_login_auth_table ${db_oracle_sys_dba_username} ${db_oracle_sys_dba_password} ${db_oracle_sys_net_service_name} "'${ip_auth}'"
			if [ $? -ne 0 ];then
				install_log "ERROR" "CHECK_ENV" "execute create_login_auth_table failed,please check ${TMPDIR}/create_login_authority.log "
				return 1
			fi
			#end to insert ip to onesdp_t_ip_auth
			
			install_log "INFO" "CHECK_ENV" "oracle user(${db_oracle_sys_username}) exist,but oracle table(${table_name}) do not exist."
			echo "sysdb_create_flag=2" > "${sysdb_create_flag}"
			typeset sysdb_check="${TMP}/sysdb_check.log"
sqlplus /nolog<<EOF > ${sysdb_check}
connect ${db_oracle_sys_username}/${db_oracle_sys_password}@${db_oracle_sys_net_service_name}
select sysdate from dual;
exit;
EOF

			#check resut
			grep "ORA-"  ${sysdb_check} >/dev/null 2>&1
			if [ $? -eq 0 ];then
				install_log "ERROR" "CHECK_ENV" "Run check sysdb's name or password or sysdb_net failed, Please see log ${sysdb_check}"
				return 1
			fi
		else 
			install_log "ERROR" "CHECK_ENV" " The oracle tables(${table_name}) belongs to oracle user(${db_oracle_sys_username}) are exist,The oracle tables(${table_name}) are not expected"
			#echo "sysdb_create_flag=1" > "${sysdb_create_flag}"
			return 1
		fi		
	fi
	rm -f "${sysdb_check}" >/dev/null 2>&1
	rm -f "${db_user_tmp_log}" >/dev/null 2>&1
	return 0
}