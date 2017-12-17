#!/usr/bin/ksh

cd $(dirname "$0")

#include common shell library
. ./commonlib.inc

################################################################################
# Function    : create_tables
# Description : create_tables
# parameter list:
#                null
# Output      : None
# Return      : 1 failed
#               0 success
################################################################################
function create_tables
{
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DB_INSTALL "Getting ne list in local host failed."
		return 1
	fi
	typeset ne_name=${RETURN[0]}
	typeset pkg_name=$(ls ${IDEPLOY_PKG_PATH}/apppkg|grep -i ${ne_name}DB|head -n 1)
	tar -xvzf ${IDEPLOY_PKG_PATH}/apppkg/$pkg_name -C ${IDEPLOY_PKG_PATH}/apppkg
	if [ $? -ne 0 ];then 
		install_log "ERROR" "INSTALL_DB" "Uncompress sub component package: ${pkg_name} failed. please check 1)disk free space 2)directory privilege 3)can be uncompressed manually or not."
		return 1
	fi
    typeset ne_name_lower=`echo ${ne_name}|tr A-Z a-z` 
	typeset db_dir=${IDEPLOY_PKG_PATH}/apppkg/${ne_name_lower}_db
	if [ ! -d "$db_dir" ];then
		install_log "ERROR" "INSTALL_DB" "Format of Uncompressed db dir is not right,please check it."
		return 1
	fi
    chmod 755 ${db_dir}/*
	typeset sql_file_names=`cat ${db_dir}/*db*.properties`
	for sql_file_name in ${sql_file_names}
	do 
		sql_file=$db_dir/$sql_file_name
		run_sql $sql_file
		if [ $? -ne 0 ];then 
			install_log "ERROR" "INSTALL_DB" "run sql $sql_file failed."
			return 1
		fi	
		install_log "INFO" "INSTALL_DB" "run sql $sql_file succeed."
	done
	install_log "INFO" "INSTALL_DB" "create tables succeed."
	return 0
}

################################################################################
# Function    : run_sql
# Description : run_sql
# parameter list:
#                null
# Output      : None
# Return      : 1 failed
#               0 success
################################################################################
function run_sql
{
	typeset sql_file="$1"
	
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

	typeset log_tmp=$(basename ${sql_file})
	typeset work_base_dir=$(dirname ${sql_file})
	typeset sql_prefix=`echo "${log_tmp}" | cut -d. -f1`
	typeset sqltmp_log="${work_base_dir}/${sql_prefix}.log"
	typeset sql_log="${work_base_dir}/exec_sql.log"
	rm -f ${sql_log}
    touch ${sql_log}
    chmod 777 ${sql_log}
    touch ${sqltmp_log} 
    chmod 777 ${sqltmp_log} 
	
su - oracle -c "sqlplus /nolog << EOF >>${sql_log}
connect ${db_user_name}/${db_user_password}@${service_url}
set pagesize 60
set linesize 512
set termout off
set heading off
set head off
set trimspool on
set feedback off

spool ${sqltmp_log}
@${sql_file}
spool off

exit;
EOF"
	
	typeset error=`cat ${sql_log} | ${GREP} -i "ERROR"` 
	if [ "x${error}" != "x" ]; then
		install_log "ERROR" "INSTALL_DB" "the sql file ${sql_file} execute failed.more detail please to see ${sqltmp_log}"
		return 1
	else
		install_log "INFO" "INSTALL_DB" "the sql file ${sql_file} execute complete."
		return 0
	fi 
}