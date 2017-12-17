#!/usr/bin/ksh

cd $(dirname "$0")

#include common shell library
. ./commonlib.inc

################################################################################
# name    : create_db_user
# describe: create_db_user.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function create_db_user
{	
	cfg_get_sec_value "${db_config_file}" "DATA-TABLE-SPACE-NAME"
	if [ $? -ne 0 ]
	then 
		install_log  "ERROR" "INSTALL" "Getting tablespace names failed."
		return 1 
	fi	
	tablespace_name=${RETURN[0]}
	
	read_value "oracle_server_sid"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get oracle_server_sid failed."
		return 1
	fi
	oracle_server_sid=${RETURN[0]}
	
	read_value "oracle_server_ip"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get oracle_server_ip failed."
		return 1
	fi
	oracle_server_ip=${RETURN[0]}	
	
	read_value "oracle_server_port"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get oracle_server_port failed."
		return 1
	fi
	oracle_server_port=${RETURN[0]}
	
	typeset service_url=${oracle_server_ip}:${oracle_server_port}/${oracle_server_sid}
	
	read_value "oracle_dba_username"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get oracle_dba_username failed."
		return 1
	fi
	oracle_dba_username=${RETURN[0]}

	read_value "oracle_dba_password"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get oracle_dba_password failed."
		return 1
	fi		
	pwd_tmp="${RETURN[0]}"
	
	decodePwd "${pwd_tmp}"
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "decode ${pwd_tmp} failed."
		return 1
	fi
	oracle_dba_password="${RETURN[0]}"
	
	read_value "db_user_name"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get db_user_name failed."
		return 1
	fi
	db_user_name=${RETURN[0]}

	read_value "db_user_password"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Get db_user_password failed."
		return 1
	fi		
	pwd_tmp="${RETURN[0]}"
	
	decodePwd "${pwd_tmp}"
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CHECK_ENV" "decode ${pwd_tmp} failed."
		return 1
	fi
	db_user_password="${RETURN[0]}"
	
	install_log INFO DB_INSTALL "Start create ${user_name}: ......"
	create_db_information_oracle "${oracle_dba_username}" "${oracle_dba_password}" "${service_url}" "${db_user_name}" "${db_user_password}" "${tablespace_name}"
	if [ $? -ne 0 ];then
		install_log ERROR DB_USER_CREATE "Create db user in database:${service_url} and the username:${oracle_username} failed."
		return 1
	fi	
	install_log INFO DB_INSTALL "Create oracle user ${user_name} successfully"
	return 0
}
################################################################################
# Function    : create_db_information_oracle
# Description : create db information oracle version
# parameter list
#                   : null
# Output            : None
# Return            : 0:success
#               1:failed
################################################################################
function create_db_information_oracle
{	
	typeset db_oracle_dba_username=$1
	typeset db_oracle_dba_password=$2
	typeset db_oracle_net_service_name=$3
	typeset db_oracle_username=$4
	typeset db_oracle_password=$5
	typeset db_oracle_default_tablespace=$6
	
	if [ "X${db_oracle_dba_username}" = "Xsys" ];then
		typeset sys_user_type="as sysdba"
	else
		typeset sys_user_type=""
	fi	
	get_oracle_home
	if [ $? -ne 0 ]; then
			install_log "DEBUG" "order" "${log_prefix}invoke read_value db_oracle_home failed."
			install_log "ERROR" "order" "read oracle home failed."
			return 1
	fi
	typeset ora_home="${RETURN[0]}"

	export ORACLE_HOME="${ora_home}"
	export PATH="${PATH}:${ORACLE_HOME}/bin"

	rm -f ${TMP}/create_db_user.sql > /dev/null 2>&1
	# create sql script
	echo "" > ${TMP}/create_db_user.sql   
	if [ $? -ne 0 ]; then
		install_log ERROR DB_INSTALL "Creating sys_db sql script file: ${TMP}/create_db_user.sql failed."
		return 1
	fi
	###### begin modify for A84D10365 ###### 
	#chmod 666 ${TMP}/create_db_user.sql
	chmod 755 ${TMP}/create_db_user.sql
	###### end modify for A84D10365 ######
	
	echo "conn ${db_oracle_dba_username}/${db_oracle_dba_password}@${db_oracle_net_service_name} ${sys_user_type};" >> ${TMP}/create_db_user.sql

	echo "                                              
	create user ${db_oracle_username}               
	identified by \"${db_oracle_password}\"
	default tablespace ${db_oracle_default_tablespace}              
	temporary tablespace TS_DSDP_TMP
	account unlock;" >> ${TMP}/create_db_user.sql
	
	echo "grant unlimited tablespace to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create sequence to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create table to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create trigger to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create procedure to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create job to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create synonym to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create view to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant create session to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant connect to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant resource to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant SELECT on user_synonyms to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant SELECT on v_\$osstat to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	#this priviledge for report
	echo "grant select on dba_objects to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	echo "grant select on dba_extents to ${db_oracle_username};" >> ${TMP}/create_db_user.sql
	
	echo "exit;" >> ${TMP}/create_db_user.sql
	typeset sql_file="${TMP}/create_db_user.sql"
	
	typeset log_tmp=$(basename ${sql_file})
	typeset work_base_dir=$(dirname ${sql_file})
	typeset sql_prefix=`echo "${log_tmp}" | cut -d. -f1`
	typeset sqltmp_log="${work_base_dir}/${sql_prefix}.log"
	typeset sql_log="${work_base_dir}/exec_sql.log"
    touch ${sql_log}
    chmod 777 ${sql_log}
    touch ${sqltmp_log} 
    chmod 777 ${sqltmp_log}  
	
su - oracle -c "sqlplus /nolog << EOF >${TMP}/create_db_user.log
spool ${sqltmp_log}
@${sql_file}
spool off

exit;
EOF"		
	
	typeset cmd_result1=`grep -i "ERROR" ${TMP}/create_db_user.log`
	typeset cmd_result2=`grep "sqlplus: not found" ${TMP}/create_db_user.log`
	typeset cmd_result3=`grep "SP2-0640" ${TMP}/create_db_user.log`
	typeset cmd_result_user_exist=`grep "ORA-01920" ${TMP}/create_db_user.log`
	###### begin modify for A84D11135 ###### 
	#rm -f ${TMP}/create_db_user.log
	###### end modify for A84D11135 ###### 
	if [ "X${cmd_result1}" != "X" ]; then
		if [ "X${cmd_result_user_exist}" != "X" ]; then	
			install_log ERROR DB_INSTALL  "ERROR" "Failed to create the db user: ${db_oracle_username}, this user has been in the database."
		else
			install_log ERROR DB_INSTALL  "ERROR" "Failed to create the db user: ${db_oracle_username}, other error"
		fi
		
		if [ "${cmd_result2}" != "" ]; then
        	install_log "ERROR" "sqlplus: not found,check the env or oracle datebase is install."
    	fi
    	
    	if [ "${cmd_result3}" != "" ]; then
    		###### begin modify for A84D11135 ###### 
        	#install_log ERROR DB_INSTALL  "Not connect,check <dba_username> <dba_userpassword> <db_oracle_net_service_name> is right."
    		install_log ERROR DB_INSTALL  "Not connect,check <dba_username> <dba_userpassword> <db_oracle_net_service_name> is right or privilege of tnsnames.ora have at least 644(-rw-r--r--)."
    		###### end modify for A84D11135 ######
    	fi
		return 1
	fi
	
	###### begin modify for A84D11135 ###### 
	rm -f ${TMP}/create_db_user.log >/dev/null 2>&1
	rm -f ${TMP}/create_db_user.sql >/dev/null 2>&1	
	rm -f ${TMP}/check_dba_role.sql >/dev/null 2>&1
	rm -f ${TMP}/check_dba_role.log >/dev/null 2>&1
	rm -f ${TMP}/check_role.sql >/dev/null 2>&1
	rm -f ${TMP}/check_role.log >/dev/null 2>&1
	###### end modify for A84D11135 ###### 	
	
	return 0
}
