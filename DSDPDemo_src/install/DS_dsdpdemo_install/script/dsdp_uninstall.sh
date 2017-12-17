#!/usr/bin/ksh

#enter into script dir
if [ `echo "$0" |grep -c "/"` -gt 0 ]; then
	cd ${0%/*}
fi

#include common shell library
. ./commonlib.inc
. ./host_info.lib
. ./delete_db.sh


#repeat install status file
typeset repeat_install_status_file="${TMP}/repeat_basic_install.ini"
typeset repeat_config_rg_file="${TMP}/repeat_config_rg.ini"
typeset INSTALL_INIT_FLAG=0
typeset INSTALL_FAIL_FLAG=1
typeset INSTALL_SUCC_FLAG=2


################################################################################
# name    : DSDP_DELETE
# describe: entry of delete.
# param1  : null
# return  : 0:success
#           1:faild
################################################################################
function DSDP_DELETE
{	
	log_echo RATE 0
	install_log INFO DSDP_DELETE "Begin to uninstall."
	log_echo RATE 5
	PROGRESS_MAX=5
	
	#if install flag file dosen't exist, return success
	if [ ! -f "${repeat_install_status_file}" ]; then
		install_log INFO DSDP_DELETE "The install status file dosen't exist, maybe the installation dosen't execute or the installation dosen't start, need not to uninstall."
		log_echo RATE 99
		return 0
	fi
	 
	read_value "user_group_name"
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_DELETE "Getting onesdp group name failed."
		return 1
	fi
	typeset user_group_name="${RETURN[0]}"
	
	get_install_user
	if [ $? -ne 0 ]; then
			install_log ERROR DSDP_INSTALL "Getting install user name failed."
			return 1
	fi
	install_user_name="${RETURN[0]}"

	user_get_user_home "${install_user_name}"
	if [ $? -ne 0 ]; then
			install_log ERROR DSDP_INSTALL "Getting home of install user failed."
			return 1
	fi
	install_user_home="${RETURN[0]}"

	read_value "isAppSelected"
	if [ $? -ne 0 ];then
		install_log ERROR BASIC_INSTALL "get isAppSelected value failed."
		return 1
	fi
	typeset isAppSelected="${RETURN[0]}"
	
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
	for ne_name in ${local_ne_list}
	do		
		if [ "X${isAppSelected}" = "Xyes" ];then
			read_value "appuser_compment_ref"
			if [ $? -ne 0 ];then
				install_log ERROR BASIC_INSTALL "get appuser_compment_ref value failed."
				return 1
			fi
			
			typeset select_ne_name=$(echo ${RETURN[0]} | sed 's/,/ /')
			
			echo "${select_ne_name}" | grep "${ne_name}" > /dev/null
			if [ $? -ne 0 ];then  #当前ne_name不属于当前appuser_compment_ref，继续下个循环appuser_compment_ref
				((idx=idx+1))
				continue
			fi
						
			read_value "user_name"
			if [ $? -ne 0 ];then
				install_log ERROR BASIC_INSTALL "get user_name value  failed."
				return 1		
			fi
			
			typeset comp_user_name="${RETURN[0]}"
			exist_comp_user=$(awk -F: '{print $1;}' /etc/passwd | grep -w "${comp_user_name}")			
			
			read_value "user_home"
			if [ $? -ne 0 ];then
				install_log ERROR BASIC_INSTALL "get user_home value  failed."
				return 1		
			fi
			
			typeset comp_user_home="${RETURN[0]}"
			deletecomp ${comp_user_name} ${comp_user_home}
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Rollback component: ${comp_id} failed."
				return 1
			fi
			
			deletecontainer ${comp_user_name} ${comp_user_home}
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Rollback container failed."
				return 1
			fi
			
			checkuser ${comp_user_name} ${comp_user_home}
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Check user failed."
				return 1
			fi
			
		fi	
	done
	
	rm -f ${repeat_install_status_file}
	rm -f ${TMP}/.*_INSTALLED
	log_echo RATE 100
	install_log INFO DSDP_DELETE "End to uninstall."
	
	return 0
}


function deleteuser
{
	typeset username=$1
	typeset userhome=$2
	#begin to delete comp user
	#just delete user in standby host and not delete home dir, if the component need install in svg
	install_log INFO DSDP_DELETE "Begin to delete ${username} user..."
	if [ "X${exist_comp_user}" = "X" ] ; then
		install_log INFO DSDP_DELETE "The user: ${username} doesn't exist, So need not to delete it. "
	else
		sed -i "/${username}/d" /var/run/utmp
		idx=0
		while [ "${idx}" -lt "5" ] 
		do	
			pkill -9 -u ${username}
			userdel -r "${username}" > "${IDEPLOY_NULL}" 2>&1
			if [ $? -ne 0 ];then
				install_log INFO DSDP_DELETE "Try to delete user:${username} again."
				((idx=idx+1))
			else
				install_log INFO DSDP_DELETE "Delete user:${username} succeed."
				break
			fi
		done
		if [ "${idx}" -eq "5" ];then
			install_log ERROR DSDP_DELETE "Delete user:${username} failed."
			return 1
		fi
	fi
	
	if [ -d ${userhome} ];then
		install_log DEBUG DSDP_DELETE "begin to remove ${comp_user_home}."
		rm -rf ${userhome} > "${IDEPLOY_NULL}" 2>&1
	fi	
}

function deletecomp
{
	install_log INFO DSDP_DELETE "Begin to unistall component."
	typeset username=$1
	typeset userhome=$2
	get_local_ne_list
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_DELETE "Getting ne list in local host failed."
		return 1
	fi
	typeset local_ne_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	
	
	for ne_name in ${local_ne_list}
	do 
		#get components list
		get_component_by_ne "${ne_name}"
		typeset comp_list=""
		typeset tmp_idx=0
		while [ ${tmp_idx} -lt ${RETNUM} ]
		do
			comp_list="${comp_list} ${RETURN[${tmp_idx}]}"
			((tmp_idx=tmp_idx+1))
		done
		for comp_id in ${comp_list}
		do
			typeset rollbackfile=${userhome}/ideploy/${comp_id}/script/${comp_id}_rollback.sh
			if [ ! -f ${rollbackfile} ]; then
				install_log ERROR DSDP_DELETE "Getting ${rollbackfile} failed."
				return 1
			fi
			su - ${username} -c ${rollbackfile}
			if [ $? -ne 0 ]; then
				install_log ERROR DSDP_DELETE "Execute ${rollbackfile} failed."
				return 1
			fi
		done
	done
}

function deletecontainer
{
	typeset username=$1
	typeset userhome=$2
	install_log INFO DSDP_DELETE "Begin to check container."
	read_value "_currentTaskNeTypeList"
	if [ $? -ne 0 ]; then
		install_log ERROR DSDP_DELETE "Getting user group id failed."
	return 1
	fi
	install_component_name="${RETURN[0]}"
	cfg_get_sec_key_value "${ne_rela_config}" "Component_Container_Relation" "${install_component_name}"
	if [ $? -ne 0 ]
	then 
		install_log ERROR LIB "Getting the key ${install_component_name} in segment Component_Container_Relation of ${ne_rela_config} failed."
		return 1 
	fi
	container_name="${RETURN[0]}"
	
	typeset modulexml=${userhome}/${container_name}/conf/module.xml
	if [ ! -f ${modulexml} ]; then
		install_log ERROR DSDP_DELETE "Getting ${modulexml} failed."
		return 1
	fi
	typeset module_num=0
	typeset available=1
	while read line
	do
		tmp=`echo ${line}|grep "<!--"`

		if [ ! "X$tmp" == "X" ]; then
			available=0
			continue
		fi
		tmp=`echo ${line}|grep "\-->"`

		if [ ! "X$tmp" == "X" ]; then
			available=1
			continue
		fi
		tmp=`echo ${line}|grep '<module'|grep -v '<modules'`

		if [ ! "X$tmp" == "X" -a ${available} -eq 1 ]; then
			((module_num=module_num+1))
		fi
	done < ${modulexml}
	if [ ${module_num} -eq 0 ]; then
		install_log INFO DSDP_DELETE "Container: ${container_name} is empty,thus remove it."
		rm -rf ${userhome}/${container_name}
	else
		install_log INFO DSDP_DELETE "Container: ${container_name} still has modules in it,no need to delete it."
	fi
}

function checkuser
{
	typeset username=$1
	typeset userhome=$2
	install_log INFO DSDP_DELETE "Begin to check user: ${username}"
	typeset container_num=`ls ${userhome}|grep _container`
	
	if [ ! "X$container_num" == "X" ]; then
		install_log INFO DSDP_DELETE "The user: ${username} still has container inside, So need not to delete it. "
		return 0
	else
		install_log INFO DSDP_DELETE "Begin to delete user: ${username} "
		deleteuser $1 $2
	fi
}

DSDP_DELETE
if [ $? -ne 0 ]; then
	install_log ERROR DSDP_DELETE "DSDP_DELETE failed."
	return 1
fi

db_repeat_install_status_file="${TMP}/.db_repeat_install.ini"
db_config_file="${IDEPLOY_PKG_PATH}/script/db.ini"
SUCCESS=2
delete_db
if [ $? -ne 0 ]; then
	install_log ERROR DB_DELETE "DSDP_DB DELETE failed."
	return 1
fi