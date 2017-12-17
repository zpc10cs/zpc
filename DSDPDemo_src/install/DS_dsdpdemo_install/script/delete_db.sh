#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

#include common shell library
. ./commonlib.inc
. ./create_tables.sh

################################################################################
# name    : delete_db
# describe: database of delete.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function delete_db
{	
	get_local_ne_list
    if [ $? -ne 0 ]; then
        install_log ERROR DB_INSTALL "Getting ne list in local host failed."
        return 1
    fi
    typeset ne_name=${RETURN[0]}
    
    get_ne_install_node "${ne_name}"
    if [ $? -ne 0 ];then
        install_log ERROR DB_INSTALL "Get install node of ne: ${ne_name} failed."
        return 1
    fi
    typeset ne_install_node="${RETURN[0]}" 
    if [ ${ne_install_node} -ne 1 ];then
        install_log "INFO" "DB_INSTALL" "This is not the first node,no need to delete DB."
        return 0
    fi
    
    install_log "INFO" "DB_INSTALL" "This is the first node,need to delete DB."
	read_value "is_create_db_space"
	if [ $? -ne 0 ];then
		install_log "ERROR" "DB_INSTALL" "get is_create_db_space value failed."
		return 1
	fi
	typeset is_create_db_space=${RETURN[0]}	


	read_value "is_create_db_user"
	if [ $? -ne 0 ];then
		install_log "ERROR" "DB_INSTALL" "get is_create_db_user value failed."
		return 1
	fi
	typeset is_create_db_user=${RETURN[0]}	
    

	if [ "X${is_create_db_user}" = "XYES" ];then		
		delete_db_user
		if [ $? -ne 0 ];then		
			return 1
		fi
	else 	
		delete_tables
		if [ $? -ne 0 ];then		
			return 1
		fi	
	fi
	
	if [ "X${is_create_db_space}" = "XYES" ];then		
		delete_tablespace
		if [ $? -ne 0 ];then		
			return 1
		fi
	fi
	
	return 0
}

################################################################################
# name    : delete_tables
# describe: database of delete.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function delete_tables
{	
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DB_INSTALL "Getting ne list in local host failed."
		return 1
	fi
	typeset ne_name=${RETURN[0]}	
    typeset ne_name_lower=`echo ${ne_name}|tr A-Z a-z` 
	typeset db_dir=${IDEPLOY_PKG_PATH}/apppkg/${ne_name_lower}_db
	if [ ! -d "$db_dir" ];then
		install_log "ERROR" "INSTALL_DB" "Format of Uncompressed db dir is not right,please check it."
		return 1
	fi
	typeset sql_file_names=`cat ${db_dir}/delete_order.properties`
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
	install_log "INFO" "INSTALL_DB" "delete tables succeed."
	return 0
}
################################################################################
# name    : delete_db_user
# describe: database of delete.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function delete_db_user
{	
	cfg_get_sec_key_value ${db_repeat_install_status_file} "create_db_user" "all" 
	if [ $? -ne 0 ];then
		install_log "ERROR" "DELETE_DB" "get key item failed,File:${db_repeat_install_status_file}, Sec:create_tablespace, Key:all"
		return 1
	fi
	result=${RETURN[0]}
	if [ ${result} -ne ${SUCCESS} ];then
		install_log "INFO" "DELETE_DB" "no need delete db_user again."		
		return 0
	fi
	user_delete "${oracle_dba_username}" "${oracle_dba_password}" "${oracle_username}" "${service_url}"
	if [ $? -ne 0 ];then
		install_log ERROR   "Delete db user in database:${service_url} and the username:${oracle_username} failed."
		return 1
	fi	
    cfg_update_sec_key_value ${db_repeat_install_status_file} "create_db_user" "all" "0"
    if [ $? -ne 0 ];then
		install_log "ERROR" "DELETE_DB" "update key item failed,File:${db_repeat_install_status_file}, Sec:create_db_user, Key:all"
		return 1
	fi
    cfg_update_sec_key_value ${db_repeat_install_status_file} "create_db_tables" "all" "0"
    if [ $? -ne 0 ];then
		install_log "ERROR" "DELETE_DB" "update key item failed,File:${db_repeat_install_status_file}, Sec:create_db_tables, Key:all"
		return 1
	fi
	return 0
}

################################################################################
# name    : delete_tablespace
# describe: database of delete.
# param1  : null
# rerurn  : 0:success
#           1:faild
################################################################################
function delete_tablespace
{		
	cfg_get_sec_key_value ${db_repeat_install_status_file} "create_tablespace" "all" 
	if [ $? -ne 0 ];then
		install_log "ERROR" "DELETE_DB" "get key item failed,File:${db_repeat_install_status_file}, Sec:create_tablespace, Key:all"
		return 1
	fi
	result=${RETURN[0]}
	if [ ${result} -ne ${SUCCESS} ];then
		install_log "INFO" "DELETE_DB" "no need delete delete_tablespace again."		
		return 0
	fi
	delete_table_space
	if [ $? -ne 0 ];then
		install_log ERROR   "Delete db user in database:${service_url} and the username:${oracle_username} failed."
		return 1
	fi	
    cfg_update_sec_key_value ${db_repeat_install_status_file} "create_tablespace" "all" "0"
    if [ $? -ne 0 ];then
		install_log "ERROR" "DELETE_DB" "update key item failed,File:${db_repeat_install_status_file}, Sec:create_tablespace, Key:all"
		return 1
	fi
    log_echo RATE 100
	return 0
}

################################################################################
# name  : delete_table_space
# desc  : delete the tablespaces we have created.
# params: null
# input : null
# output: null
# return: 0 succ, 1 failed
################################################################################
function delete_table_space
{	
	ts_info="${TMP}/tablespace_info.ini"
	cfg_get_sec_value "${db_config_file}" "SERVICE-TABLE-SPACE-NAME"
	if [ $? -ne 0 ]
	then 
		install_log  "ERROR" "DELETE_DB" "Getting tablespace names failed."
		return 1 
	fi
	
	typeset table_space_names[0]=""
	typeset idx=0
	typeset table_space_nums="${RETNUM}"
	typeset success_nums=0
	while [ ${idx} -lt ${table_space_nums} ]
	do 
		tmp_space_name=${RETURN[${idx}]}
		grep -i ${tmp_space_name} ${ts_info} >/dev/null 2>&1
		if [ $? -eq 0 ]
		then 
			table_space_names[${success_nums}]=${RETURN[${idx}]}	
			((success_nums=success_nums+1))			
		fi		
		((idx=idx+1))
	done
	
	idx=0
    errflag=0
	while [ ${idx} -lt ${success_nums} ]
	do
		typeset drop_ts="${TMP}/drop_ts_$$.sh"
		typeset drop_ts_log="${TMP}/drop_ts_$$.log"
		
		echo "#!/usr/bin/ksh" > "${drop_ts}"
		echo "" >> "${drop_ts}"
		echo "export ORACLE_SID=${oracle_sid}" >> "${drop_ts}"
		echo "export ORACLE_HOME=${db_oracle_home}" >> "${drop_ts}"
		echo 'export PATH=${ORACLE_HOME}/bin:${PATH}' >> "${drop_ts}"
		echo "" >> "${drop_ts}"
		echo "sqlplus ${oracle_dba_username}/${oracle_dba_password}@${service_url} ${sys_user_type} <<xEOF" >> "${drop_ts}"		 
		echo "drop tablespace ${table_space_names[${idx}]} INCLUDING CONTENTS  AND DATAFILES;" >> "${drop_ts}"
		echo "exit" >>"${drop_ts}"
		echo "xEOF" >> "${drop_ts}"
		chmod 755 "${drop_ts}"		
		su - oracle -c "${drop_ts}" > "${drop_ts_log}"
		typeset rt=0		
		typeset drop_info=$(cat ${drop_ts_log})			
		typeset ts_name_tmp=$(echo ${table_space_names[${idx}]} | tr a-z A-Z)
		echo "${drop_info}"|grep "^Tablespace dropped.$"  1>/dev/null 2>&1
		if [ $? -eq 0 ]
		then 				
			cfg_update_sec_key_value ${db_repeat_install_status_file} "create_tablespace" "${ts_name_tmp}" "0"
			install_log "INFO" "DELETE_DB" "Droping tablespace ${table_space_names[${idx}]} successed."
            rm -f "${drop_ts_log}"
            rm -f "${drop_ts}"
		else 
			cfg_update_sec_key_value ${db_repeat_install_status_file} "create_tablespace" "${ts_name_tmp}" "1"
			install_log "ERROR" "DELETE_DB" "Droping tablespace ${table_space_names[${idx}]} failed.Please check it manual.See the log $TMP/${drop_ts_log}."		
			((errflag=errflag+1))		
		fi
		((idx=idx+1))
	done   	
    if [ $errflag -ne 0 ];then
        install_log "ERROR" "DELETE_DB" "Droping tablespace failed.See the log in $TMP."
        return 1 
    fi
	return 0 
}

db_repeat_install_status_file="${TMP}/.db_repeat_install.ini"
db_config_file="${IDEPLOY_PKG_PATH}/script/db.ini"
SUCCESS=2

read_value "is_need_db"
if [ $? -ne 0 ];then
	install_log "ERROR" "DELETE_DB" "get is_need_db value failed."
	return 1
fi
typeset is_need_db=${RETURN[0]}		
if [ "X${is_need_db}" = "XNO" ];then
	install_log "INFO" "DELETE_DB" "no need to delete_db."
	return 0		
fi

#get oracle sys dba username
get_oracle_home
if [ $? -ne 0 ]; then
	install_log ERROR DELETE_DB "Get db ORACLE_HOME failed.Please check it."
	return 1
fi
db_oracle_home="${RETURN[0]}"
export ORACLE_HOME=${db_oracle_home}
export PATH=${db_oracle_home}/bin:${PATH}

read_value "oracle_server_ip"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get oracle_server_ip failed."
	return 1
fi
oracle_server_ip=${RETURN[0]}

read_value "oracle_server_sid"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get oracle_server_sid failed."
	return 1
fi
oracle_server_sid=${RETURN[0]}

read_value "oracle_server_port"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get oracle_server_port failed."
	return 1
fi
oracle_server_port=${RETURN[0]}

typeset service_url=${oracle_server_ip}:${oracle_server_port}/${oracle_server_sid}
	
read_value "oracle_dba_username"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get oracle_dba_username failed."
	return 1
fi
oracle_dba_username=${RETURN[0]}
if [ "X${oracle_dba_username}" = "Xsys" ];then
	typeset sys_user_type="as sysdba"
else
	typeset sys_user_type=""
fi

read_value "oracle_dba_password"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get oracle_dba_password failed."
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
	install_log ERROR DB_USER_DELETE "Get db_user_name failed."
	return 1
fi
oracle_username=${RETURN[0]}

read_value "db_user_password"
if [ $? -ne 0 ];then
	install_log ERROR DB_USER_DELETE "Get db_user_password failed."
	return 1
fi
pwd_tmp="${RETURN[0]}"

decodePwd "${pwd_tmp}"
if [ $? -ne 0 ]; then
	install_log "ERROR" "CHECK_ENV" "decode ${pwd_tmp} failed."
	return 1
fi
oracle_password="${RETURN[0]}"
	