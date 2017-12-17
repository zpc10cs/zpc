#!/usr/bin/ksh

cd $(dirname "$0")

#include common shell library
. ./commonlib.inc
. ./create_tablespace.sh
. ./create_db_user.sh
. ./create_tables.sh

################################################################################
# description:	the local ip must be existing in /etc/hosts
# parameters:	null
# return:		0 succeed,1 fail
################################################################################
get_localhost_ip
if [ $? -ne 0 ]; then
    install_log "ERROR" "install_db" "invoke function: get_localhost_ip failed."
    return 1
fi
local_host_ip="${RETURN[0]}"
grep -e "^${local_host_ip}" /etc/hosts > /dev/null 2>&1
if [ $? -ne 0 ]; then
    install_log "ERROR" "install_db" "local ip ${local_host_ip} is not in /etc/hosts."
    return 1
fi    


################################################################################
# function:		generate_repeat_install_status_file
# description:	generate repeat install status file
# parameters:	null
# return:		0 succeed,1 fail
################################################################################
function generate_repeat_install_status_file
{	
	if [ -f ${repeat_install_status_file} ];then
		install_log INFO INSTALL "File ${repeat_install_status_file} already exists"
		return 0
	fi
	generate_tablespace_info
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "generate tablespace info failed."
		return 1
	fi
	echo "
[ALL]
all=0">${repeat_install_status_file}
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Generate flag to ${repeat_install_status_file} failed"
		return 1
	fi
	echo "
[create_tablespace]
all=0">> ${repeat_install_status_file}
	cat ${TMP}/tablespace_info.ini|awk '!a[$1]++' | while read LINE 
	do
		echo "${LINE}=0">>${repeat_install_status_file}
	done
	if [ $? -ne 0 ];then
		install_log ERROR INSTALL "cat ${TMP}/tablespace_info.ini to ${repeat_install_status_file} failed"
		return 1
	fi
    echo "
[create_db_user]
all=0">> ${repeat_install_status_file}
    if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Generate flag to ${repeat_install_status_file} failed"
		return 1
	fi
        echo "
[create_db_tables]
all=0">> ${repeat_install_status_file}
    if [ $? -ne 0 ];then
		install_log ERROR INSTALL "Generate flag to ${repeat_install_status_file} failed"
		return 1
	fi
	install_log INFO INSTALL "Generate ${repeat_install_status_file} success"
		
	return 0
}

##############################
##############################
repeat_install_status_file="${TMP}/.db_repeat_install.ini"
SUCCESS=2

#generate repeat_install.ini
if [ ! -f ${repeat_install_status_file} ];then
    generate_repeat_install_status_file
    if [ $? -ne 0 ]; then
        install_log ERROR APP_INSTALL "Generating repeat install status file failed."
        return 1
    fi
fi

read_value "is_need_db"
if [ $? -ne 0 ];then
	install_log "ERROR" "DB_INSTALL" "get is_need_db value failed."
	return 1
fi
typeset is_need_db=${RETURN[0]}	
if [ "X${is_need_db}" = "XNO" ];then		
	install_log "INFO" "DB_INSTALL" "is_need_db=NO,so skip."
	return 0
fi

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


get_local_ne_list
if [ $? -ne 0 ]; then
	install_log ERROR DB_INSTALL "Getting ne list in local host failed."
	return 1
fi
typeset ne_name=${RETURN[0]}

#if the node is the first,do it
get_ne_install_node "${ne_name}"
if [ $? -ne 0 ];then
	install_log ERROR DB_INSTALL "Get install node of ne: ${ne_name} failed."
	return 1
fi
typeset ne_install_node="${RETURN[0]}" 
if [ ${ne_install_node} -ne 1 ];then
	install_log "INFO" "DB_INSTALL" "This is not the first node,no need to create DB."
	return 0
fi

install_log "INFO" "DB_INSTALL" "This is the first node,need to create DB."
######################
######################
if [ "X${is_create_db_space}" = "XYES" ];then		
	create_tablespace 
	if [ $? -ne 0 ]; then
		install_log "ERROR" "DB_INSTALL" "create_tablespace failed."
		return 1
	fi
	install_log "INFO" "DB_INSTALL" "create tablespace success."
fi

######################
######################
if [ "X${is_create_db_user}" = "XYES" ];then		
	cfg_get_sec_key_value ${repeat_install_status_file} "create_db_user" "all"
	if [ $? -ne 0 ];then
		install_log "ERROR" "INSTALL_DB" "Get key item failed,File:${repeat_install_status_file}, Sec:create_db_user, Key:all."
		return 1
	fi
	result=${RETURN[0]}
	if [ ${result} -ne ${SUCCESS} ];then
		create_db_user
		if [ $? -ne 0 ]; then
			install_log "ERROR" "DB_INSTALL" "create_db_user failed."
			return 1
		fi    
		cfg_update_sec_key_value ${repeat_install_status_file} "create_db_user" "all" "2"
		if [ $? -ne 0 ];then
			install_log "ERROR" "INSTALL_DB" "Update key item failed,File:${repeat_install_status_file}, Sec:create_db_user, Key:all, Value:1"
			return 1
		fi
		install_log "INFO" "DB_INSTALL" "create db user success."
	else
		install_log "INFO" "DB_INSTALL" "create db user is already success,no need to create again."
	fi
fi


######################
######################
cfg_get_sec_key_value ${repeat_install_status_file} "create_db_tables" "all"
if [ $? -ne 0 ];then
    install_log "ERROR" "INSTALL_DB" "Get key item failed,File:${repeat_install_status_file}, Sec:create_db_tables, Key:all."
    return 1
fi
result=${RETURN[0]}
if [ ${result} -ne ${SUCCESS} ];then
    create_tables
    if [ $? -ne 0 ]; then
        install_log "ERROR" "DB_INSTALL" "create_tables failed."
        return 1
    fi
    cfg_update_sec_key_value ${repeat_install_status_file} "create_db_tables" "all" "2"
    if [ $? -ne 0 ];then
        install_log "ERROR" "INSTALL_DB" "Update key item failed,File:${repeat_install_status_file}, Sec:create_db_tables, Key:all, Value:1"
        return 1
    fi
   install_log "INFO" "DB_INSTALL" "create tables success."
else
    install_log "INFO" "DB_INSTALL" "create tables is already success,no need to create again."
fi

rm -rf ${TMP}/*.sh

