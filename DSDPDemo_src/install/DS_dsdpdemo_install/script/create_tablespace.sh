#!/usr/bin/ksh

cd $(dirname "$0")

#include common shell library
. ./commonlib.inc

################################################################################
# name  : check_tablespace
# desc  : check tablespace
# params:null
#         
# input : null
# output: null
# return: db_config_file
################################################################################
function  check_tablespace
{
	#check tablespace is or not exit
	install_log "INFO" "INSTALL_DB" "Begin to check tablespace already existed"
	typeset ts_info="${TMP}/tablespace_info.ini"
	 
	typeset sql_file="${TMP}/check_tablespace_existed.sh"
	echo "#!/usr/bin/ksh" > "${sql_file}"
	echo "" >> "${sql_file}"
	echo "export ORACLE_SID=${oracle_server_sid}" >> "${sql_file}"
	echo "export ORACLE_HOME=${oracle_home}" >> "${sql_file}"
	echo 'export PATH=${ORACLE_HOME}/bin:${PATH}' >> "${sql_file}"
	echo "" >> "${sql_file}"
	echo "sqlplus /nolog <<xEOF" >> "${sql_file}"
    echo "conn ${oracle_dba_username}/${oracle_dba_password}@${oracle_service_url} ${sys_user_type};" >>"${sql_file}"
	echo "set pagesize 60" >> "${sql_file}"
	echo "set linesize 512"  >> "${sql_file}"
	echo "set termout off" >> "${sql_file}"
	echo "set heading off"  >> "${sql_file}"
	echo "set head off"  >> "${sql_file}"
	echo "set trimspool on" >> "${sql_file}"
	echo "set feedback off" >> "${sql_file}"
	
	#get tablespace info
	typeset tablespace_name=$(awk -F"#" '{print $1}' ${db_config_file} | sed '/^[ 	]*$/d' | sed -n "/^[     ]*\[[   ]*SERVICE-TABLE-SPACE-NAME[  ]*\]/,/^[       ]*\[.*\]/p" |sed '/^[       ]*\[.*\]/d' |awk '!a[$1]++')
	

    
	echo "select tablespace_name from dba_tablespaces;" >> "${sql_file}"
	echo "exit" >>"${sql_file}"
	echo "xEOF" >> "${sql_file}"
	
	chmod 755 ${sql_file}
	#from oracle user exec 
	
	su - ${oracle_user} -c "${sql_file}" > "${TMP}/check_tablespace.log"
	
	grep -i "ORA-" ${TMP}/check_tablespace.log >/dev/null 2>&1
	if [ $? -eq 0 ];then
		install_log ERROR INSTALL "find tablespace in system failed."
		return 1
	fi
	
	for ts in ${tablespace_name}
	do
		grep -w "${ts}" ${TMP}/check_tablespace.log >/dev/null 2>&1
		if [ $? -eq 0 ];then
			cfg_update_sec_key_value ${repeat_install_status_file} "create_tablespace" "${ts}" "2"
			if [ $? -ne 0 ];then
				install_log "ERROR" "INSTALL_DB" "Update key item failed,File:${repeat_install_status_file}, Sec:ALL, Key:all, Value:2"
				return 1
			fi
			#add flag for uninstall
			sed -i "/${ts}/d" ${ts_info}
			if [ $? -ne 0 ];then
				install_log "ERROR" "INSTALL_DB" "Modify tablespace info file :${ts_info} failed"
				return 1
			fi		
		fi	
	done
	
	#rm -r ${TMP}/check_tablespace.log   >/dev/null 2>&1
	return 0
}

################################################################################
# name  : generate_tablespace_info
# desc  : get resource group name for net element.
# params:
#         $1 lcapdb or dsdpdb or lcap and dsdpdb togather
# input : null
# output: RETURN[0]
# return: 0 succ, 1 failed
################################################################################
function generate_tablespace_info
{
	if [ ! -f ${cfgFile} ];then
		install_log ERROR INSTALL "${cfgFile} does not exist."
		return 1
	fi
	cfg_get_sec_value "${cfgFile}" "SERVICE-TABLE-SPACE-NAME"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "read SERVICE-TABLE-SPACE-NAME in ${cfgFile} failed."
		return 1
	fi
	typeset i=0
	if [ -f ${TMP}/tablespace_info.ini ];then
		rm -f ${TMP}/tablespace_info.ini
		if [ $? -ne 0 ];then
			install_log ERROR INSTALL "delete ${TMP}/tablespace_info.ini failed."
			return 1
		fi
	fi
	while [ $i -lt ${RETNUM} ]
	do
		echo "${RETURN[$i]}" >>${TMP}/tablespace_info.ini
		if [ $? -ne 0 ];then
			install_log ERROR INSTALL "echo RETURN[$i] to ${TMP}/tablespace_info.ini failed,please disk capacity."
			return 1
		fi
		((i=i+1))
	done
	sed -i '/^[ \t]*$/d' ${TMP}/tablespace_info.ini
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Modify ${TMP}/tablespace_info.ini failed."
		return 1
	fi
	
}

################################################################################
# name  : update_config
# desc  : update_config
# params:
#         $1 ne name
# input : null
# output: RETURN[0]
# return: 0 succ, 1 failed
################################################################################
function update_config
{	
	
	if [ "X${oracle_mode}" = "Xsingle" ];then
		install_log INFO INSTALL "Single instance need not update ${cfgFile}"
		return 0
	fi
	#if [ ${local_db_flag} -eq 1 ];then
	#    typeset lv_prefix="lcap_lv_size"
	#	typeset asm_prefix="lcap_asm"
	#else
        #typeset lv_prefix="lv_size"	
	#	typeset asm_prefix="asm"
	#fi	
	install_log INFO INSTALL "Start to update ${cfgFile}..."
	log_echo RATE 10
	typeset rate_time=10
	typeset rate_time1=10	
	
	cfg_get_sec_value "${cfgFile}" "SERVICE-TABLE-SPACE-NAME"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Get section SYSTEM-TABLE-SPACE-NAME of ${cfgFile} failed"
		return 1
	fi
	num=${RETNUM}
	i=0
	while [ $i -lt ${num} ];
	do
		TABLESPACE[i]="${RETURN[$i]}"
		((i=i+1))
	done
	read_value "lv_size_data"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Read value lv_size_data in config.propertites failed"
		return 1
	fi
	typeset size_data="${RETURN[0]}"
	read_value "lv_size_idx"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Read value lv_size_idx in config.propertites failed"
		return 1
	fi
	size_idx="${RETURN[0]}"
	
	read_value "idx_tablespace_num"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Read value idx_tablespace_num in config.propertites failed"
		return 1
	fi
	num_idx="${RETURN[0]}"
	
	read_value "dat_tablespace_num"
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Read value dat_tablespace_num in config.propertites failed"
		return 1
	fi
	num_data="${RETURN[0]}"
	
	i=0
	while [ $i -lt ${num} ];
	do
		tablespace_name=${TABLESPACE[i]}
		install_log INFO INSTALL "Update tablespace ${tablespace_name} config in ${cfgFile}"
		
		echo "${tablespace_name}" | egrep -i "_IDX|_CDRIDX" >/dev/null
		if [ $? -eq 0 ];then			
			size="${size_idx}"
			tablespace_size="${num_idx}"
		else			
			size="${size_data}"
			tablespace_size="${num_data}"
		fi
		
		cfg_update_sec_key_value "${cfgFile}" "${tablespace_name}" "size" "${size}"
		if [ $? -ne 0 ];then
			install_log ERROR INSTALL "Update key value failed, File:${cfgFile},Section:${tablespace_name},Key: size"
			return 1
		fi
		
		cfg_update_sec_key_value "${cfgFile}" "${tablespace_name}" "datafile_num" "${tablespace_size}"
		if [ $? -ne 0 ];then
			install_log ERROR INSTALL "Update key value failed, File:${cfgFile},Section:${tablespace_name},Key: datafile_num"
			return 1
		fi
		cfg_get_sec_key_value "${cfgFile}" "${tablespace_name}" "template"
	    if [ $? -ne 0 ];then 
	    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space} key:template"
	    	return 1
	    fi
	    typeset template=${RETURN[0]}
		typeset num_tmp=0
		typeset number_add=0
		while [ ${num_tmp} -lt ${tablespace_size} ];
		do
			((number_add=num_tmp+1))
			cfg_get_sec_key_value "${cfgFile}" "${tablespace_name}" "datafile[${num_tmp}]"
			if [ $? -ne 0 ];then 
				install_log "DEBUG" "INSTALL_DB" "Can not find item ,File:${cfgFile};section:${table_space_names[${idx}]} key:datafile[${num_tmp}],Write it!"
				cfg_write_sec_key_value "${cfgFile}" "${tablespace_name}" "datafile[${num_tmp}]" "${template}${number_add}"
				if [ $? -ne 0 ];then 
					install_log "ERROR" "INSTALL_DB" "Write item failed,File:${cfgFile};section:${tablespace_name} key:datafile[${num_tmp}],Value ${template}${number_add}"
					return 1
				fi
			else
				cfg_update_sec_key_value "${cfgFile}" "${tablespace_name}" "datafile[${num_tmp}]" "${template}${number_add}"
				if [ $? -ne 0 ];then 
					install_log "ERROR" "INSTALL_DB" "Update item failed,File:${cfgFile};section:${table_space_names[${idx}]} key:datafile[${num_tmp}],Value ${template}${number_add}"
					return 1
				fi
			fi
			((num_tmp=num_tmp+1))
			((dba_file_num=dba_file_num+1))
		done		
		((i=i+1))
		rate_time1=$(echo $((rate_time1+0.2)))
		rate_time=$(echo "${rate_time1}"|awk -F. '{print $1}')
		log_echo RATE ${rate_time}
	done
	install_log INFO INSTALL "Update ${cfgFile} success"
	return 0
}

################################################################################
# name  : generating_sql
# desc  : generate sql script for creating tablespace.
# params:
#         $1 flag [dual | single]
#         $2 tablespace name
# input : null
# output: RETURN[0]
# return: 0 succ, 1 failed
################################################################################
function generating_sql
{
	typeset table_space=$1
	typeset asmgroup_name=$2
	typeset size=$4
	typeset num=$3
	#typeset dual_ts_file="${TMP}/dual_host_tablespace_size.ini"
	typeset sql=""
	RETURN[0]=""
	tablespace_file=""
	if [ "X${table_space}" = "XTS_DSDP_TMP" ]
	then
		sql="create temporary tablespace ${table_space} tempfile"
	else
		sql="create tablespace ${table_space} datafile"
	fi
	if [ "X${oracle_mode}" = "Xdual" ];then
		typeset idx=0
		while [ ${idx} -lt ${num} ]
		do
			cfg_get_sec_key_value "${cfgFile}" "${table_space}" "datafile[${idx}]"
		    if [ $? -ne 0 ];then 
		    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space} key:datafile[${idx}]"
		    	return 1
		    fi
		    tablespace_file=${RETURN[0]}
		    cfg_get_sec_key_value "${cfgFile}" "${table_space}" "asm_group"
		    if [ $? -ne 0 ];then 
		    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space} key:asm_group"
		    	return 1
		    fi
		    service_asm_group=${RETURN[0]}
		    
		    if [ ${idx} == 0 ]; then
		    	
		    	if [ "X${table_space}" = "XTS_DSDP_TMP" ];then
					echo "${sql} '+${service_asm_group}(TEMPFILE)/${oracle_server_sid}/${tablespace_file}' size ${size};" >tmp_sql
				else
					echo "${sql} '+${service_asm_group}(DATAFILE)/${oracle_server_sid}/${tablespace_file}' size ${size};" >tmp_sql
				fi
		    else
	            if [ "X${table_space}" = "XTS_DSDP_TMP" ]
		    	then
		    		echo "alter tablespace ${table_space} add tempfile '+${service_asm_group}(TEMPFILE)/${oracle_server_sid}/${tablespace_file}' size ${size};" >>tmp_sql
		    	else
		    		echo "alter tablespace ${table_space} add datafile '+${service_asm_group}(DATAFILE)/${oracle_server_sid}/${tablespace_file}' size ${size};" >>tmp_sql
				fi	
			fi
			((idx=idx+1))
		done
		sql=`cat tmp_sql`
		rm -f tmp_sql
	fi
	
	if [ "X${oracle_mode}" = "Xsingle" ];then
		cfg_get_sec_key_value "${db_config_file}" "TABLE-SPACE-SIZE" "${table_space}"
		if [ $? -ne 0 ]
		then 
			install_log "ERROR" "INSTALL_DB" "Getting the tablespace size of ${table_space} failed."
			return 1
		fi	
		typeset size_str="${RETURN[0]}"
		
		typeset init_size=$(echo "${size_str}"|awk -F, '{print $1}')
		typeset extent_size=$(echo "${size_str}"|awk -F, '{print $2}')
		typeset max_size=$(echo "${size_str}"|awk -F, '{print $3}')
		
		cfg_get_sec_key_value "${db_config_file}" "TABLE-SPACE-NAME-SINGLE" "${table_space}"
		if [ $? -ne 0 ]
		then 
			install_log "ERROR" "INSTALL_DB" "Getting the db file name of ${table_space} failed."
			return 1 
		fi
		typeset db_file="${RETURN[0]}"
		
		if [ -e ${db_file} ]
		then
			get_valid_file_name "${db_file}" "${table_space}"
			db_file="${RETURN[0]}"
		fi 
        #get oracle_base
        get_oracle_base
         if [ $? -ne 0 ]; then
            install_log "ERROR" "CREATE_TB_SPACE" "invoke function: get_oracle_base failed."
            return 1
        fi
        typeset oracle_base="${RETURN[0]}"
        db_file_ab=`eval echo $db_file`
		typeset dir_name=$(dirname "${db_file_ab}")          
        get_localhost_ip
        if [ $? -ne 0 ]; then
            install_log "ERROR" "CREATE_TB_SPACE" "invoke function: get_host_type failed."
            return 1
        fi
        local_host_ip="${RETURN[0]}"
        if [ "X${local_host_ip}" != "X${oracle_server_ip}" ]
		then 
			read_value "remote_oracle_password"
			if [ $? -ne 0 ];then
				install_log ERROR CREATE_TB_SPACE "Get remote_oracle_password failed."
				return 1
			fi
			remote_pwd_tmp=${RETURN[0]}	
		 
			decodePwd "${remote_pwd_tmp}"
			if [ $? -ne 0 ]; then
				install_log "ERROR" "CREATE_TB_SPACE" "decode ${remote_pwd_tmp} failed."
				return 1
			fi
			remote_oracle_password="${RETURN[0]}"
			
            typeset get_remote_oracle_base="${IDEPLOY_PKG_PATH}/script/get_remote_oracle_base.exp"	
			chmod 755 ${get_remote_oracle_base}
            ${get_remote_oracle_base}  oracle@"${oracle_server_ip}" "${remote_oracle_password}" > remote_oracle_base.tmp
            oracle_base=`tail -n 1 remote_oracle_base.tmp|awk -F"\r" '{print $1}'`
            if [ X$oracle_base = X"" ]; then
				install_log "ERROR" "CREATE_TB_SPACE" "get remote ORACLE_BASE failed,please check the oracle."
				return 1
			fi            
            rm -rf remote_oracle_base.tmp
            db_file_ab=`eval echo $db_file`
            dir_name=$(dirname "${db_file_ab}") 
            
			typeset create_datafile_path="${IDEPLOY_PKG_PATH}/script/create_datafile_path.exp"	
			chmod 755 ${create_datafile_path}
            ${create_datafile_path}  oracle@"${oracle_server_ip}" "${remote_oracle_password}" "${dir_name}" > /dev/null 2>&1
            if [ $? -ne 0 ];then
                install_log ERROR INSTALL "Creating directory: ${dir_name} for tablespace failed."
                return 1
            fi  
        else
            su - oracle -c "mkdir -p $dir_name;chmod 755 $dir_name"
            if [ $? -ne 0 ];then
                install_log ERROR INSTALL "Creating directory: ${dir_name} for tablespace failed."
                return 1
            fi 
		fi
        
		sql="${sql} '${db_file_ab}'"
		if [ "X${init_size}" != "X" ]
		then 
			sql="${sql} size ${init_size}m"
		fi
		
		if [ "X${extent_size}" != "X" ]
		then 
			sql="${sql} autoextend on next ${extent_size}m"
		fi
		
		if [ "X${max_size}" != "X" ]
		then 
			sql="${sql} maxsize ${max_size}m"
		fi
		sql="${sql};"
	fi
	RETURN[0]="${sql}"
	return 0 
}

################################################################################
# name  : get_valid_file_name
# desc  : getting a valid file name if a filename exists.
# params:
#         $1 the file name.
#         $2 tablespace name
# input : null
# output: RETURN[0]
# return: 0 succ, 1 failed
################################################################################
function get_valid_file_name
{
	typeset file_name="${1}"
	typeset tablespace_name="${2}"
	
	typeset dir_name=$(dirname ${file_name})
	
	typeset idx=1
	while [ -e "${dir_name}/${tablespace_name}_${idx}.dbf" ]
	do
		((idx=idx+1))
	done
	
	RETURN[0]="${dir_name}/${tablespace_name}_${idx}.dbf"
	
	return 0
}

################################################################################
# name  : create_table_space
# desc  : create table space.
# params: null
# input : null
# output: null
# return: 0 succ, 1 failed
################################################################################
function create_table_space
{
	install_log INFO INSTALL "Begin to create tablespaces." 
	get_oracle_home
	if [ $? -ne 0 ]; then
			install_log "DEBUG" "order" "${log_prefix}invoke read_value db_oracle_home failed."
			install_log "ERROR" "order" "read oracle home failed."
			return 1
	fi
	oracle_home="${RETURN[0]}"	
	
	read_value "oracle_server_sid"
	if [ $? -ne 0 ];then
		install_log ERROR CREATE_TB_SPACE "Get oracle_server_sid failed."
		return 1
	fi
	oracle_server_sid=${RETURN[0]}
	
	read_value "oracle_server_ip"
	if [ $? -ne 0 ];then
		install_log ERROR CREATE_TB_SPACE "Get oracle_server_ip failed."
		return 1
	fi
	oracle_server_ip=${RETURN[0]}	   
    
	
	read_value "oracle_server_port"
	if [ $? -ne 0 ];then
		install_log ERROR CREATE_TB_SPACE "Get oracle_server_port failed."
		return 1
	fi
	oracle_server_port=${RETURN[0]}
	
	oracle_service_url=${oracle_server_ip}:${oracle_server_port}/${oracle_server_sid}
	
	read_value "oracle_dba_username"
	if [ $? -ne 0 ];then
		install_log ERROR CREATE_TB_SPACE "Get oracle_dba_username failed."
		return 1
	fi
	oracle_dba_username=${RETURN[0]}
	if [ "X${oracle_dba_username}" = "Xsys" ];then
		sys_user_type="as sysdba"
	else
		sys_user_type=""
	fi	

	read_value "oracle_dba_password"
	if [ $? -ne 0 ];then
		install_log ERROR CREATE_TB_SPACE "Get oracle_dba_password failed."
		return 1
	fi		
	pwd_tmp="${RETURN[0]}"
	
	decodePwd "${pwd_tmp}"
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CREATE_TB_SPACE" "decode ${pwd_tmp} failed."
		return 1
	fi
	oracle_dba_password="${RETURN[0]}"
	
	check_tablespace
	if [ $? -ne 0 ]; then
		install_log "ERROR" "CREATE_TB_SPACE" "decode ${pwd_tmp} failed."
		return 1
	fi
	# start to modify parameter db_files
	dba_file_num_tmp=1000
	if [ ${dba_file_num} -gt 900 ];then
		dba_file_num_tmp=$(expr ${dba_file_num} + 100)
	fi
	
	typeset change_db_file="${TMP}/change_db_file.sh"
	typeset change_db_log="${TMP}/change_db_log.log"
	echo "#!/usr/bin/ksh" > "${change_db_file}"
	echo "" >> "${change_db_file}"
	echo "export ORACLE_SID=${oracle_server_sid}" >> "${change_db_file}"
	echo "export ORACLE_HOME=${oracle_home}" >> "${change_db_file}"
	echo 'export PATH=${ORACLE_HOME}/bin:${PATH}' >> "${change_db_file}"
	echo "" >> "${change_db_file}"
	echo "sqlplus /nolog <<xEOF" >> "${change_db_file}"	
    echo "conn ${oracle_dba_username}/${oracle_dba_password}@${oracle_service_url} ${sys_user_type};" >>"${change_db_file}"
	echo "exit" >>"${change_db_file}"
	echo "xEOF" >> "${change_db_file}"
	chmod 755 "${change_db_file}"	
	su - oracle -c "${change_db_file}" > "${change_db_log}" &
	typeset change_db_file_process="$!"
	typeset tmp_idx=0
	#for the overtime limit
	while [ true ]
	do
		((tmp_idx=tmp_idx+1))
		ps aux|awk '{print $2}'|grep -w ${change_db_file_process} 1>/dev/null 2>&1
		if [ $? -ne 0 ]
		then 
			install_log "DEBUG" "INSTALL_DB" "The process of changing db file has been terminated."
			break
		else
			install_log "INFO" "INSTALL_DB" "The process of changing db file is running, please wait..."
			sleep 3
		fi
		if [ ${tmp_idx} -gt 300 ];then
			install_log "ERROR" "INSTALL_DB" "The process of changing db file has not been terminated, time is over!"
			return 1
		fi
	done
	grep "^ORA-" "${change_db_log}" 1>/dev/null 2>&1 
	typeset rt=$?
	typeset start_info=$(cat ${change_db_log})
	if [ $rt -eq 0 ]
	then
		install_log "ERROR" "LIB" "Startup the oracle instance failed,please make sure it has already started and try again."
		return 1 
	else 
		install_log "DEBUG" "LIB" "Startup the oracle instance successed."
	fi 
	#end to modify parameter db_files
	now_rate=65
	
	install_log "INFO" "INSTALL_DB" "The node need to create tablespace, begin to create tablespace."
	
	cfg_get_sec_value "${db_config_file}" "SERVICE-TABLE-SPACE-NAME"
	if [ $? -ne 0 ]
	then 
		install_log  "ERROR" "INSTALL_DB" "Getting tablespace names failed."
		return 1 
	fi
	
	typeset table_space_names[0]=""
	typeset idx=0
	typeset table_space_nums="${RETNUM}"
	typeset success_nums=0
	while [ ${idx} -lt ${table_space_nums} ]
	do 
		table_space_names[${idx}]=${RETURN[${idx}]}
		((idx=idx+1))
	done
	
	idx=0
	while [ ${idx} -lt ${table_space_nums} ]
	do
		cfg_get_sec_key_value ${repeat_install_status_file} "create_tablespace" "${table_space_names[${idx}]}"
		if [ $? -ne 0 ];then 
	    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${repeat_install_status_file};section:create_tablespace key:${table_space_names[${idx}]}"
	    	return 1
	    fi
		result=${RETURN[0]}
		if [ ${result} -eq ${SUCCESS} ];then
			install_log "INFO" "INSTALL_DB" "tablespace ${table_space_names[${idx}]} does exist in the current database, no need create again."
			((idx=idx+1))
			continue
		fi
		cfg_get_sec_key_value "${cfgFile}" "${table_space_names[${idx}]}" "asm_group"
	    if [ $? -ne 0 ];then 
	    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space_names[${idx}]} key:asm_group"
	    	return 1
	    fi
	    asm_group_name=${RETURN[0]}
	    
	    cfg_get_sec_key_value "${cfgFile}" "${table_space_names[${idx}]}" "datafile_num"
	    if [ $? -ne 0 ];then 
	    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space} key:datafile_num"
	    	return 1
	    fi
	    typeset datafile_num=${RETURN[0]}
		
		
	    cfg_get_sec_key_value "${cfgFile}" "${table_space_names[${idx}]}" "size"
	    if [ $? -ne 0 ];then 
	    	install_log "ERROR" "INSTALL_DB" "Get item failed,File:${cfgFile};section:${table_space} key:size"
	    	return 1
	    fi
	    typeset tablespace_size=${RETURN[0]}
		#typeset table_space_str=${table_space_names[${idx}]}
		#typeset create_table_space_flag="0"
		
		typeset table_space=${table_space_names[${idx}]}
		#typeset raw_device=$(echo ${table_space_str}|awk -F= '{print $2}')
		generating_sql "${table_space}" "${asm_group_name}" "${datafile_num}" "${tablespace_size}"
			
		typeset rt=$?
		if [ $rt -ne 0 ]
		then 
			install_log "ERROR" "INSTALL_DB" "Generating the sql of create tablespace failed."
			install_log "ERROR" "INSTALL_DB" "Creating tablespace ${table_space} failed."				
			return 1
		fi
		typeset sql=${RETURN[0]}
		typeset sql_file="${TMP}/create_table_space_${table_space}.sh"
		typeset exec_log="${TMP}/create_table_space_${table_space}.log"
			
		# generate shell script
		echo "#!/usr/bin/ksh" > "${sql_file}"
		echo "" >> "${sql_file}"
		echo "export ORACLE_SID=${oracle_server_sid}" >> "${sql_file}"
		echo "export ORACLE_HOME=${oracle_home}" >> "${sql_file}"
		echo 'export PATH=${ORACLE_HOME}/bin:${PATH}' >> "${sql_file}"
		echo "" >> "${sql_file}"
		echo "sqlplus /nolog <<xEOF" >> "${sql_file}"
		echo "conn ${oracle_dba_username}/${oracle_dba_password}@${oracle_service_url} ${sys_user_type};" >>"${sql_file}"
		echo "${sql}" >> "${sql_file}"
		echo "exit" >>"${sql_file}"
		echo "xEOF" >> "${sql_file}"
		chmod 755 "${sql_file}"
			
		su - ${oracle_user} -c "${sql_file}" > "${exec_log}" &
		typeset create_table_space_pid="$!"
		install_log "DEBUG" "INSTALL_DB" "The process id of creating tablespace ${table_space} is ${create_table_space_pid}."
		
		typeset tmp_idx=0
		#for the overtime limit
		while [ true ]
		do
			((tmp_idx=tmp_idx+1))
			ps aux|awk '{print $2}'|grep -w ${create_table_space_pid} 1>/dev/null 2>&1
			if [ $? -ne 0 ]
			then 
				install_log "DEBUG" "INSTALL_DB" "The process of creating tablespace has been terminated."
				break
			else
				install_log "INFO" "INSTALL_DB" "Creating tablespace process of ${table_space} is running, please wait..."
				sleep 3
			fi
		done
			
		typeset seconds=""
		((seconds=tmp_idx*3))
		install_log "DEBUG" "INSTALL_DB" "The process of creating tablespace ${table_space} spend ${seconds} seconds."
		
		grep "^Tablespace created.$" "${exec_log}" 1>/dev/null 2>&1
		typeset rt=$?
		typeset exec_info=$(cat ${exec_log} |grep "ORA-")
		#rm -f ${exec_log}
		if [ $rt -ne 0 ]
		then 						
			install_log "ERROR" "INSTALL_DB" "Creating tablespace ${table_space} failed."
			install_log "ERROR" "INSTALL_DB" "The failed reason: ${exec_info} "
			cfg_update_sec_key_value ${repeat_install_status_file} "create_tablespace" "${table_space_names[${idx}]}" "1"
			return 1
		else						
			install_log "INFO" "INSTALL_DB" "Creating tablespace ${table_space} succeed."
		fi					
		cfg_update_sec_key_value ${repeat_install_status_file} "create_tablespace" "${table_space_names[${idx}]}" "2"
		now_rate1=$(echo $((now_rate+1.5)))
		now_rate=$(echo "${now_rate1}"|awk -F. '{print $1}')
		log_echo RATE "${now_rate}"
		((idx=idx+1))
	done
	install_log "INFO" "INSTALL_DB" "Creating all tablespace succeed."
	return 0
}

#################################################################################
# name  : create_tablespace
# desc  : create_tablespace function for install.
# params: null
# input : null
# output: null
# return: 0 succ, 1 failed
################################################################################
function create_tablespace
{
	install_log INFO INSTALL "Start to install tablespace..."    

	cfg_get_sec_key_value ${repeat_install_status_file} "create_tablespace" "all"
	if [ $? -ne 0 ];then
		install_log "ERROR" "INSTALL_DB" "Get key item failed,File:${repeat_install_status_file}, Sec:create_tablespace, Key:all."
		return 1
	fi
	result=${RETURN[0]}
	if [ ${result} -ne ${SUCCESS} ];then
		if [ "X${oracle_mode}" = "Xdual" ];then          
			update_config
			if [ $? -ne 0 ];then
				install_log "ERROR" "INSTALL_DB" "update_config failed"
				return 1
			fi
		fi	
		log_echo RATE 20
		create_table_space
		if [ $? -ne 0 ]
		then 
			install_log "ERROR" "INSTALL_DB" "create_table_space failed."
			return 1
		fi
		log_echo RATE 90	
		cfg_update_sec_key_value ${repeat_install_status_file} "create_tablespace" "all" "2"
		if [ $? -ne 0 ];then
			install_log "ERROR" "INSTALL_DB" "Update key item failed,File:${repeat_install_status_file}, Sec:create_tablespace, Key:all, Value:1"
			return 1
		fi
		install_log "INFO" "INSTALL_DB" "create_table_space success."
	fi
	
	log_echo RATE 100
	return 0
}

################################################################################
# global variables declare area
################################################################################
#install_finsh_file="${TMP}/.install_finished"
db_config_file="${IDEPLOY_PKG_PATH}/script/db.ini"
cfgFile=${db_config_file}
oracle_user=oracle
oracle_group=oinstall
oracle_home=""
oracle_server_sid=""
oracle_base=""
ora_dbbak_dir=""
oracle_server_ip=""
oracle_server_port=""
oracle_service_url=""
oracle_dba_username=""
oracle_dba_password=""
sys_user_type=""


oracle_system_password=""
oracle_sys_password=""
read_value "oracle_mode"
if [ $? -ne 0 ]; then
	install_log "ERROR" "INSTALL_DB" "Getting the config value of _hostType failed."
	return 1
fi
oracle_mode="${RETURN[0]}"
################################################################################
# execute area
################################################################################
#init parameter db_files size
dba_file_num=0


