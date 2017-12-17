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
			typeset pkg_names_list=`(cd "${IDEPLOY_PKG_PATH}"; ls apppkg/ | sed -n "/^${pkg_pattern}$/p") 2>"${IDEPLOY_NULL}"`
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
			su - "${user_name}" -c "${install_filename} \"${cluster_idx}\" " 2>"${IDEPLOY_NULL}"
			if [ $? -ne 0 ]; then
				install_log ERROR BASIC_INSTALL "Installing component: ${comp_id} failed."
				return 1
			fi
			touch ${TMP}/.${user_name}_${comp_id}_INSTALLED
		fi
						
		log_echo RATE ${PROGRESS_MAX}
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
	
	if [ "X${isDBAppSelected}" = "Xyes" ];then
		get_oracle_home
		if [ $? -ne 0 ]; then
			install_log ERROR BASIC_INSTALL "read oracle home failed."
			return 1
		fi
		typeset ora_home="${RETURN[0]}"
		
		echo "\nsetenv ORACLE_HOME ${ora_home}\n" >> ${SCRIPT_DIR}/dsdp_cshrc
	fi
	
	read_value "user_group_name"
	if [ $? -ne 0 ];then
		install_log ERROR BASIC_INSTALL "get user_group_id value  failed."
		return 1		
	fi
	typeset user_group_name="${RETURN[0]}"
	
	bin_scripts_list="*app.sh dir_tool.sh register_comp.sh version.sh status logview.sh redisview showcfg.sh showcfg updatecfg.sh updatecfg showerr.sh showerr logset logset.sh"
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