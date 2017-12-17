#!/usr/bin/ksh

. ./commonlib.inc
. ./create_user.sh
. ./check_db.sh


################################################################################
# name	: deploy_common_software
# describe: install monitor and jdk.
# param1  :
# return  : 0:success
#		   1:failed
################################################################################
function deploy_common_software
{
	user_name="${1}"
	user_home="${2}"
	#install j2se&monitor
	#get the package name of j2se&monitor
	#get components list
	get_component_by_ne "COMMON"
	typeset comp_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		comp_list="${comp_list} ${RETURN[${tmp_idx}]}"
	
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG BASIC_INSTALL "comp_list: ${comp_list}"
	for comp_id in ${comp_list}
	do
		if [ -f ${TMP}/.${user_name}_${comp_id}_INSTALLED ];then
			install_log DEBUG BASIC_INSTALL "${comp_id} has alread been installed,no need to install again."
			continue
		fi
		get_package_by_subComp "${comp_id}"
		if [ $? -ne 0 ]; then
			install_log ERROR BASIC_INSTALL "Getting package patterns of component failed."
			set_repeat_install_flag "COMPONENT" "${comp_id}.uncompress" "${INSTALL_FAIL_FLAG}"
			return 1
		fi
		typeset pkg_patterns_list=""
		typeset tmp_idx=0
		while [ ${tmp_idx} -lt ${RETNUM} ]
		do
			pkg_patterns_list="${pkg_patterns_list} ${RETURN[${tmp_idx}]}"
		
			((tmp_idx=tmp_idx+1))
		done
		install_log DEBUG BASIC_INSTALL "pkg_patterns: ${pkg_patterns_list}"
		#loop for every pattern
		typeset all_pkg_file_name_list=""
		for pkg_pattern in ${pkg_patterns_list}
		do
			install_log DEBUG BASIC_INSTALL "****pkg_pattern: ${pkg_pattern}"
			#match pkg file name
			typeset pkg_names_list=$(cd "${IDEPLOY_PKG_PATH}"; ls apppkg/ | sed -n "/^${pkg_pattern}$/p")
			typeset current_pkg=`echo "${pkg_names_list}"| sed "s/[ \t]//g"`
			if [ "X${current_pkg}" = "X" ]
			then
				install_log ERROR BASIC_INSTALL "Can't find the package of \"${pkg_pattern}\"."
				return 1
			fi
			
			all_pkg_file_name_list="${all_pkg_file_name_list} ${pkg_names_list}"
			
			for pkg_name in ${pkg_names_list}
			do
				#untar pkg to install user's home
					install_log DEBUG BASIC_INSTALL "_____pkg_name: ${pkg_name}"
					#uncompress gzip pkg use runner user
					su - ${user_name} -c "mkdir ${user_home};cd ${user_home};gzip -dc ${IDEPLOY_PKG_PATH}/apppkg/${pkg_name} | tar xf -" 2>"${IDEPLOY_NULL}"
					if [ $? -ne 0 ]; then
						install_log ERROR BASIC_INSTALL "Uncompress sub component package: ${pkg_name} to directory: ${user_home} failed. please check 1)disk free space 2)directory privilege 3)can be uncompressed manually or not."
						return 1
					fi
			done
		done

		all_pkg_file_name_list=`echo "${all_pkg_file_name_list}" | sed "s/[ \t]//g"`
		if [ "X${all_pkg_file_name_list}" = "X" ]; then
			install_log ERROR BASIC_INSTALL "Can't find packages for sub component: ${sub_comp_id}."
			return 1
		fi			
		install_log INFO BASIC_INSTALL "Uncompress component packages successfully."

		#install step (2): call sub component install script
		#grant execute privileges to interface script
		if [ ! -d "${user_home}/ideploy/${comp_id}" ]; then
			install_log ERROR BASIC_INSTALL "Maybe package format is incorrect, can not find directory: ${user_home}/ideploy/${comp_id}."
			return 1
		fi

		cd "${user_home}"; find "./ideploy/${comp_id}/script" -type d | xargs -n 1 -i chmod -R 750 "{}"
		if [ $? -ne 0 ]; then
			install_log ERROR BASIC_INSTALL "Grant execute privilege to interface script failed."
			return 1
		fi

		
		# before call component script, call function <env_init_cmd> to initialize component shell environment.
		# modify for INSTALL_TASK_DIR
		env_init_cmd "${user_home}/ideploy/${comp_id}/script"
		if [ $? -ne 0 ];then
			install_log ERROR BASIC_INSTALL "The user ${user_name} env init failed."
			return 1
		fi
		
		#if comp_id_install.sh does not exist, it need not call
		typeset install_filename="${user_home}/ideploy/${comp_id}/script/${comp_id}_install.sh"
		if [ ! -f ${install_filename} ]
		then
			install_log DEBUG BASIC_INSTALL "the file of ${comp_id}_install.sh does not exist,so it needn't call ${comp_id}_install.sh"
			touch ${TMP}/.${user_name}_${comp_id}_INSTALLED
		else
			su - "${user_name}" -c "${install_filename}" 2>"${IDEPLOY_NULL}"
			if [ $? -ne 0 ]; then
				install_log ERROR BASIC_INSTALL "Installing component: ${comp_id} failed."
				return 1
			fi
			touch ${TMP}/.${user_name}_${comp_id}_INSTALLED
		fi
						
		log_echo RATE ${PROGRESS_MAX}
		if [ "X${comp_id}" = "Xmicro-container" ]; then
			read_value "_currentTaskNeTypeList"
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Getting user group id failed."
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
			su - "${user_name}" -c "mv micro-container/ ${container_name}/"
		fi
		install_log INFO BASIC_INSTALL "Installing component: ${comp_id} succeeded."
	done	
}

################################################################################
# name	: create_app_user
# describe: create_app_user
# param1  : null
# output  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function create_app_user
{
	typeset user_name=${1}
	typeset user_password=${2}
	typeset user_home=${3}
	typeset ne_name=${4}
	
	read_value "user_group_id"
	if [ $? -ne 0 ];then
		install_log ERROR BASIC_INSTALL "get user_group_id value  failed."
		return 1		
	fi
	typeset user_group_id="${RETURN[0]}"

	#get_ne_index_in_localmachine "${ne_name}"
	get_single_ne_index "${ne_name}"
	if [ $? -ne 0 ]
	then 
		install_log "ERROR" "BASIC_INSTALL" "Getting current NE ${ne_name} in local machine's index failed"
		return 1 
	fi
	typeset single_idx="${RETURN[0]}"

	get_user_create_flag
	if [ $? -ne 0 ]; then
		install_log ERROR BASIC_INSTALL "Getting group create flag failed."
		return 1
	fi
	typeset user_create_flag="${RETURN[0]}"
	
	# create global group for DSDP
	if [ ${user_create_flag} -eq 0 ]; then
		create_app_run_user "${user_name}" "${user_password}" "${user_home}"  "${user_group_id}" "" "" "${single_idx}" 
		if [ $? -eq 0 ]; then
			install_log INFO BASIC_INSTALL "Creating user: ${user_name} succeed."
		elif [ $? -eq ${ERR_USER_USER_EXIST} -o $? -eq ${ERR_USER_USE_EXIST_USER} ];then
			install_log INFO BASIC_INSTALL "The user: ${user_name} has been created already, need not to create again."
			return 0
		else
			install_log ERROR BASIC_INSTALL "Creating user: ${user_name} failed."
			return 1
		fi
	fi
	
	#install bin tools
	deploy_dir_bin "${user_name}" "${user_home}"
	if [ $? -ne 0 ]; then
		install_log ERROR BASIC_INSTALL "install bin tools failed."
		return 1
	fi
	#install monitor&j2se
	deploy_common_software "${user_name}" "${user_home}"
	if [ $? -ne 0 ]; then
		install_log ERROR BASIC_INSTALL "install monitor or j2se failed."
		return 1
	fi
	

}

################################################################################
# name	: set_user_create_flag
# describe: set user create flag to repeat_install.ini
# param1  : null
# output  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function set_user_create_flag
{
	cfg_update_sec_key_value "${repeat_install_status_file}" "ALL" "user.create" "2"
	if [ $? -ne 0 ]; then
		install_log DEBUG BASIC_INSTALL "Updating user create falg in file: ${repeat_install_status_file} failed."
		return 1
	fi
	
	return 0
}

################################################################################
# name	: get_group_create_flag
# describe: get group create flag from repeat_install.ini
# param1  : null
# output  : RETURN[0]
# rerurn  : 0:success
#		   1:failed
################################################################################
function get_user_create_flag
{
	RETURN[0]=""
	
	cfg_get_sec_key_value "${repeat_install_status_file}" "ALL" "user.create"
	if [ $? -ne 0 ]; then
		install_log ERROR BASIC_INSTALL "Getting user create flag failed."
		return 1
	fi
	#return value has been in RETURN[0]
	
	return 0
}

typeset repeat_install_status_file="${TMP}/repeat_basic_install.ini"
typeset ne_rela_config="${IDEPLOY_PKG_PATH}/script/up_small.ini"


function deploy_dir_bin
{
	typeset user_name=$1 
	typeset user_home=$2

	read_value "isDBAppSelected"
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "get isDBAppSelected value failed."
		return 1
	fi
	typeset isDBAppSelected=${RETURN[0]}
	##TODO
	#if [ "X${isDBAppSelected}" = "Xyes" ];then
	#	get_oracle_home
	#	if [ $? -ne 0 ]; then
	#		install_log ERROR BASIC_INSTALL "read oracle home failed."
	#		return 1
	#	fi
	#	typeset ora_home="${RETURN[0]}"	
	#	echo "\nsetenv ORACLE_HOME ${ora_home}\n" >> ${SCRIPT_DIR}/dsdp_cshrc
	#fi
	
	read_value "user_group_name"
	if [ $? -ne 0 ];then
		install_log ERROR BASIC_INSTALL "get user_group_id value  failed."
		return 1		
	fi
	typeset user_group_name="${RETURN[0]}"
	
	bin_scripts_list="*app.sh dir_tool.sh register_comp.sh version.sh cdpath.sh cdcheck.sh status logview.sh redisview showcfg.sh showcfg updatecfg.sh updatecfg showerr.sh showerr logset logset.sh"
	for bin_script in ${bin_scripts_list}
	do
		cp ${SCRIPT_DIR}/${bin_script} ${user_home}/bin
	done
	
	cp -r ${SCRIPT_DIR}/shelllib ${user_home}/bin
	cp -r ${SCRIPT_DIR}/tools ${user_home}/bin/tools
	cat  ${SCRIPT_DIR}/dsdp_cshrc >> ${user_home}/.cshrc
	
	chown -R ${user_name}:${user_group_name}  ${user_home}/bin
	chmod +x ${user_home}/bin/* >/dev/null 2>&1
}

################################################################################
# name	: generate_repeat_install_status_file
# describe: generate repeat install status file.
# param1  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function generate_repeat_install_status_file
{
	if [ ! -f "${repeat_install_status_file}" ]; then
		touch "${repeat_install_status_file}" > "${IDEPLOY_NULL}" 2>&1
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Generating repeat installation status file failed."
			return 1
		fi
		chmod 666 "${repeat_install_status_file}" > "${IDEPLOY_NULL}" 2>&1
		
		#generate
		echo "[ALL]" > "${repeat_install_status_file}"
		echo "all=0" >> "${repeat_install_status_file}"
		echo "group.create=0" >> "${repeat_install_status_file}"
		echo "user.create=0" >> "${repeat_install_status_file}"
		echo "" >> "${repeat_install_status_file}"
		echo "[COMPONENT]" >> "${repeat_install_status_file}"
		
		# get ne list in local host
		get_local_ne_list
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Getting NE list in local host failed."
			return 1
		fi
		typeset local_ne_list=""
		typeset tmp_idx=0
		while [ ${tmp_idx} -lt ${RETNUM} ]
		do
			local_ne_list="${local_ne_list} ${RETURN[${tmp_idx}]}"
			((tmp_idx=tmp_idx+1))
		done
		typeset ne_name=""
		for ne_name in ${local_ne_list}
		do

			echo "${ne_name}.flag=0" >> "${repeat_install_status_file}"
			typeset db_create_ne_list="TAG UPM SNS CONTENT SUBSCRIPTION ORDER CHARGING PRODUCT publicinfo CGW PAYMENT CAMPAIGN MARKETINGMGMT"
			for db_create_ne in ${db_create_ne_list}
			do
				if [ ${ne_name} = "${db_create_ne}" ];then
					echo "${ne_name}.dbuser.create=0" >> "${repeat_install_status_file}"
				fi
			done
			#get components list
			get_component_by_ne "${ne_name}"
			typeset result=$?
			echo ${RETURN[0]}
			if [ $result -ne 0 ]; then
				if [ $result -eq 2 ]; then
					install_log DEBUG APP_INSTALL "${ne_name} no component."
					continue
				else
					install_log ERROR APP_INSTALL "Getting components list of ne: ${ne_name} failed."
					return 1
				fi
			fi

			typeset comp_list=""
			typeset tmp_idx=0
			while [ ${tmp_idx} -lt ${RETNUM} ]
			do
				comp_list="${comp_list} ${RETURN[${tmp_idx}]}"
				((tmp_idx=tmp_idx+1))
			done
			install_log DEBUG APP_INSTALL "components list of ne(${ne_name}) : ${comp_list}"
			
			#loop for every component
			for comp_id in ${comp_list}
			do				
				echo "${comp_id}.uncompress=0" >> "${repeat_install_status_file}"
				echo "${comp_id}.app.install=0" >> "${repeat_install_status_file}"				
			done
			echo "" >> "${repeat_install_status_file}"
		done
	fi
	
	return 0
}

################################################################################
# name	: get_repeat_install_flag
# describe: get repeat install flag in repeat install config file.
# param1  : 
#		   $1	section name
#		   $2	key name
# output  : RETURN[0]
# rerurn  : 0:success
#		   1:failed
################################################################################
function get_repeat_install_flag
{
	RETURN[0]=""
	
	if [ $# -ne 2 ]; then
		install_log DEBUG APP_INSTALL "Parameters count of function: get_repeat_install_flag error."
		return 1
	fi
	typeset sec_name="$1"
	typeset key_name="$2"
	typeset comp_key_name=$(echo $key_name | awk -F\. '{print $1}')
	
	cfg_get_sec_key_value "${repeat_install_status_file}" "${sec_name}" "${key_name}"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting install flag of: [${sec_name}]${key_name} failed."
		return 1
	fi
	
	return 0
}

################################################################################
# name	: get_group_create_flag
# describe: get group create flag from repeat_install.ini
# param1  : null
# output  : RETURN[0]
# rerurn  : 0:success
#		   1:failed
################################################################################
function get_group_create_flag
{
	RETURN[0]=""
	
	cfg_get_sec_key_value "${repeat_install_status_file}" "ALL" "group.create"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting group create flag failed."
		return 1
	fi
	#return value has been in RETURN[0]
	
	return 0
}

################################################################################
# name	: set_group_create_flag
# describe: set group create flag to repeat_install.ini
# param1  : null
# output  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function set_group_create_flag
{

	cfg_update_sec_key_value "${repeat_install_status_file}" "ALL" "group.create" 2
	if [ $? -ne 0 ]; then
		install_log DEBUG APP_INSTALL "Updating group create falg in file: ${repeat_install_status_file} failed."
		return 1
	fi
	
	return 0
}

################################################################################
# name	: create_run_group
# describe: create run group of DSDP.
# param1  :
#		   $1	group name
#		   $2	group id
# output  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function create_run_group
{
	install_log DEBUG APP_INSTALL "Parameters: $@."
	if [ $# -ne 2 ]; then
		install_log DEBUG APP_INSTALL "Parameters count of function: create_run_group error."
		return 1
	fi
	typeset group_name="$1"
	typeset group_id="$2"
	
	user_create_group "${group_name}" "${group_id}"
	typeset rt=$?
	
	if [ ${rt} -eq ${SUCC} -o ${rt} -eq ${ERR_USER_USE_EXIST_GROUP} ]; then
		install_log DEBUG APP_INSTALL "Creating group succeed."
		return 0
	else
		install_log DEBUG APP_INSTALL "Creating group failed, error code: ${rt}."
		return 1
	fi
}

function deploy_new_comp
{
	typeset username=$1
	typeset userhome=$2
	#get micro-container pattern
	cfg_get_sec_key_value "${ne_rela_config}" "COMPONENT-PKG-REF" "micro-container"
	if [ $? -ne 0 ]
	then 
		install_log ERROR LIB "Getting the key micro-container in segment COMPONENT-PKG-REF of ${ne_rela_config} failed."
		return 1 
	fi
	container_pkg="${RETURN[0]}"
	typeset pkg_names_list=$(cd "${IDEPLOY_PKG_PATH}"; ls apppkg/ | sed -n "/^${container_pkg}$/p")
	typeset current_pkg=`echo "${pkg_names_list}"| sed "s/[ \t]//g"`
	su - ${user_name} -c "cd ${userhome};gzip -dc ${IDEPLOY_PKG_PATH}/apppkg/${current_pkg} | tar xf -" 2>"${IDEPLOY_NULL}"
	read_value "_currentTaskNeTypeList"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting user group id failed."
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
	su - "${user_name}" -c "mv micro-container/ ${container_name}/"

	install_log INFO BASIC_INSTALL "Installing component: ${comp_id} succeeded."
}
function main
{
	log_echo RATE 0
	install_log INFO APP_INSTALL "Begin to install."
		
	#generate repeat_install.ini
	if [ ! -f ${repeat_install_status_file} ];then
		generate_repeat_install_status_file
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Generating repeat install status file failed."
			return 1
		fi
	fi
	
	typeset sub_comp_num=5
	typeset sub_comp_seq=0
	install_log DEBUG APP_INSTALL "Sub component count in localhost is : ${sub_comp_num}."
	
	log_echo RATE 5
	PROGRESS_MAX=10
	
		read_value "user_group_name"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting up_user_group_name failed."
		return 1
	fi
	user_group_name="${RETURN[0]}"
	
	read_value "user_group_id"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting user group id failed."
		return 1
	fi
	user_group_id="${RETURN[0]}"
		
	get_group_create_flag
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting group create flag failed."
		return 1
	fi
	typeset group_create_flag="${RETURN[0]}"
		
	# create global group for DSDP
	if [ ${group_create_flag} -eq 0 ]; then
		typeset local_group_name_exist=`${AWK} -F: '{print $1}' /etc/group | ${GREP} ^${user_group_name}$`
		typeset group_name=`awk -F: -vgid="${user_group_id}" '
			{
				if ($3 == gid)
				{
					print $1
					exit(0)
				}
			}' "/etc/group"`
	
		if [ "x${local_group_name_exist}" != "x" -a "x${group_name}" = "x${local_group_name_exist}" ]
		then
			install_log DEBUG APP_INSTALL "the group name \"${user_group_name}\" id ${user_group_id} has already exist in local machine,no need to creat"
		elif [ "x${group_name}" = "x" -a "x${local_group_name_exist}" = "x" ];then
			create_run_group "${user_group_name}" "${user_group_id}"
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Creating group: ${user_group_name} failed.  \
(At: ${IDEPLOY_PKG_PATH}/script/dsdp_install.sh: $LINENO)"
				return 1
			fi
			install_log INFO APP_INSTALL "Creating group: ${user_group_name} succeed."
		else	
			install_log "ERROR" "DSDP_INSTALL" "The gid $group_id or ${user_group_name} is exist and is not a couple!"
			return 1 
		fi
		
		# update group create flag to user.chk
		set_group_create_flag
		if [ $? -ne 0 ]; then
			install_log DEBUG APP_INSTALL "Setting group create flag failed."
		fi
	fi
	
	typeset idx=0
	read_value "appuser_compment_ref"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "appuser_compment_ref value failed."
		return 1
	fi
	typeset select_ne_name=$(echo ${RETURN[0]} | sed 's/,/ /')

	read_value "user_name"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "get user_name value failed."
		return 1		
	fi
	ne_user_name="${RETURN[0]}"
	
	read_value "user_password"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "get user_password value  failed."
		return 1		
	fi
	pwd_tmp="${RETURN[0]}"
	decodePwd "${pwd_tmp}"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "decode password failed."
		((flag=flag+1))
	fi
	ne_user_password="${RETURN[0]}"
	
	read_value "user_home"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "get user_home value  failed."
		return 1		
	fi
	ne_user_home="${RETURN[0]}"

	echo "${select_ne_name}" | grep "${ne_name}" > /dev/null
	if [ $? -ne 0 ];then  #当前ne_name不属于当前appuser_compment_ref，继续下个循环appuser_compment_ref
		((idx=idx+1))
		continue
	fi
	
	grep -w ${ne_user_name} /etc/passwd > /dev/null
	if [ $? -ne 0 ];then   #用户在单板上不存在，就去创建
		create_app_user  "${ne_user_name}" "${ne_user_password}" "${ne_user_home}" "${ne_name}"						
		if [ $? -ne 0 ];then 
			install_log INFO APP_INSTALL "create app user ${ne_user_name} for ${ne_name} failed.May be it will be cteated in other component."					
			typeset count=0
			while [ ${count} -lt 30 ]  #判断用户是否存在
			do
				grep -w ${ne_user_name} /etc/passwd > /dev/null
				if [ $? -ne 0 ];then
					install_log INFO APP_INSTALL "The user: ${ne_user_name} has not been created , please wait..."
					((count=count+1))
					sleep 2
				else					
					break;
				fi
			done
			if [ ${count} -eq 30 ];then #如果依然不存在，再创建一次
				create_app_user  "${ne_user_name}" "${ne_user_password}" "${ne_user_home}" "${ne_name}"	
				if [ $? -ne 0 ];then 
					install_log ERROR APP_INSTALL "create app user ${ne_user_name} for ${ne_name} failed."					
					return 1
				fi
			fi
		fi
		install_log INFO APP_INSTALL "create app user ${ne_user_name} for ${ne_name} succeed."	
	    else 
			deploy_new_comp ${ne_user_name} ${ne_user_home}
	fi
}

main