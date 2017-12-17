#!/usr/bin/ksh
#enter into script dir
if [ `echo "$0" |grep -c "/"` -gt 0 ]; then
	cd ${0%/*}
fi
#include common shell library
. ./commonlib.inc
. ./create_user.sh
. ./check_db.sh
. ./create_user_for_comp.sh
. ./change_mod.sh

#repeat install status file
typeset repeat_install_status_file="${TMP}/repeat_basic_install.ini"
#ha dual host script
#typeset conntool_pkg_name="${IDEPLOY_PKG_PATH}/script/conntool.tar.gz"
typeset net_type_file="${IDEPLOY_PKG_PATH}/script/up_small.ini"
typeset teastore_client_pkg="${IDEPLOY_PKG_PATH}/script/ONIP_DataGrid_V*R*C*_TEASTORE_RUN_Linux.tar.gz"
#global variables declare
typeset INSTALL_INIT_FLAG=0
typeset INSTALL_FAIL_FLAG=1
typeset INSTALL_SUCC_FLAG=2
#DATE
typeset date=$(date '+%Y%m%d%H%M%S')

function app_install
{	
	ne_name=$1
	ne_user_name=$2
	ne_user_home=$3
	chmod -R 755 *
	typeset index=0
	while [ ${index} -lt 30 ]   #µÈ´ýjdk¾ÍÐ÷
	do									
		su - ${ne_user_name} -c "java -version" > /dev/null 
		if [ $? -eq 0 ];then
			install_log INFO APP_INSTALL "The user: ${ne_user_name} jdk is ready."
			break
		fi
		sleep 2
		((index=index+1))	
	done			
	if [ ${index} -eq 30 ];then
		install_log ERROR APP_INSTALL "${ne_user_name} jdk is not ready."	
		return 1
	fi
			
	install_log DEBUG DSDP_INSTALL "It's single, need to deploy_single_app_autostart."
	deploy_single_app_autostart "${ne_name}" "${ne_user_name}"
	if [ $? -ne 0 ];then
		install_log ERROR DSDP_INSTALL "invoke deploy_single_app_autostart \"${ne_name}\" \"${ne_user_name}\" failed."
		return 1
	fi
	install_log DEBUG DSDP_INSTALL "End to deploy_single_app_autostart."
			
	#get components list
	get_component_by_ne "${ne_name}"
	typeset comp_list=""
	typeset tmp_idx=0
	while [ ${tmp_idx} -lt ${RETNUM} ]
	do
		comp_list="${comp_list} ${RETURN[${tmp_idx}]}"
		((tmp_idx=tmp_idx+1))
	done
	install_log DEBUG APP_INSTALL "comp_list: ${comp_list}"
	
	#loop for every component
	for comp_id in ${comp_list}
	do
		install_log INFO APP_INSTALL "Begin to install component: ${comp_id}."					
		comp_user_name="${ne_user_name}"		
		comp_user_home="${ne_user_home}"
		comp_user_shell="/usr/bin/csh"

		install_log DEBUG APP_INSTALL "comp_user_name: ${comp_user_name}"
		install_log DEBUG APP_INSTALL "comp_user_home: ${comp_user_home}"
		install_log DEBUG APP_INSTALL "comp_user_shell: ${comp_user_shell}"
		install_log DEBUG APP_INSTALL "user_group_name: ${user_group_name}"
		
		#if component pkg install succeed, continue next component
		get_repeat_install_flag "COMPONENT" "${comp_id}.app.install"
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Getting install flag of component: ${comp_id} failed."
			return 1
		fi
		typeset comp_install_flag="${RETURN[0]}"
		
		if [ "${comp_install_flag}" -eq "${INSTALL_SUCC_FLAG}" ]; then
			install_log INFO APP_INSTALL "All subcomponents install succeeded, it is unnecessary to install again, continue next component."
			#echo progress
			#((sub_comp_seq=sub_comp_seq+sub_comp_count))
			#typeset cur_progress_pos=`echo "x" | awk -vseq=${sub_comp_seq} -vcnt=${sub_comp_num} '{ print 10 + int(85/cnt*seq); }'`
			#log_echo RATE ${cur_progress_pos}
			#PROGRESS_MAX=${cur_progress_pos}
			continue
		fi

		#install components
		#loop for every component
		install_log INFO APP_INSTALL "Begin to install component: ${comp_id}."
		
		#output install progress
		#((sub_comp_seq=sub_comp_seq+1))
		#typeset cur_progress_pos=`echo "x" | awk -vseq=${sub_comp_seq} -vcnt=${sub_comp_num} '{ print 10 + int(85/cnt*seq); }'`
		#set_progress_range ${PROGRESS_MAX} ${cur_progress_pos}

		#log_echo RATE ${PROGRESS_MIN}
		
		#if this subcomponent has installed succeeded, skip it and continue next one.
		get_repeat_install_flag "COMPONENT" "${comp_id}.app.install"
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Getting install flag of subcomponent: ${sub_comp_id} failed."
			return 1
		fi
		typeset comp_install_flag="${RETURN[0]}"
		
		if [ "${comp_install_flag}" -eq "${INSTALL_SUCC_FLAG}" ]; then
			install_log INFO APP_INSTALL "This component ${comp_id} install succeed, need not to install again, continue next component."
			continue
		fi
		#install step (1): untar sub component software package
		get_repeat_install_flag "COMPONENT" "${comp_id}.uncompress"
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Getting total install flag failed."
			return 1
		fi
		typeset uncompress_flag="${RETURN[0]}"
		install_log DEBUG APP_INSTALL "uncompress flag: ${uncompress_flag}"
				
		if [ "${uncompress_flag}" -ne "${INSTALL_SUCC_FLAG}" ]; then
			install_log INFO APP_INSTALL "Begin to uncompress component packages."
			get_package_by_subComp "${comp_id}"
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Getting package patterns of sub component failed."
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
			install_log DEBUG APP_INSTALL "pkg_patterns: ${pkg_patterns_list}"
			#loop for every pattern
			typeset all_pkg_file_name_list=""
			for pkg_pattern in ${pkg_patterns_list}
			do
				install_log DEBUG APP_INSTALL "****pkg_pattern: ${pkg_pattern}"
				
				#match pkg file name
				typeset pkg_names_list=$(cd "${IDEPLOY_PKG_PATH}"; ls apppkg/ | sed -n "/^${pkg_pattern}$/p")
				typeset current_pkg=`echo "${pkg_names_list}"| sed "s/[ \t]//g"`
				if [ "X${current_pkg}" = "X" ]
				then
					install_log ERROR APP_INSTALL "Can't find the package of \"${pkg_pattern}\"."
					return 1
				fi
				
				all_pkg_file_name_list="${all_pkg_file_name_list}${pkg_names_list}"
				
				for pkg_name in ${pkg_names_list}
				do
					#untar pkg to install user's home
						install_log DEBUG APP_INSTALL "_____pkg_name: ${pkg_name}"
						#uncompress gzip pkg use runner user
						su - ${comp_user_name} -c "mkdir ${comp_user_home};cd ${comp_user_home};$(get_uncompress_util ${pkg_name}) -dc ${IDEPLOY_PKG_PATH}/apppkg/${pkg_name} | tar xf -" 2>"${IDEPLOY_NULL}"
						if [ $? -ne 0 ]; then
							install_log ERROR APP_INSTALL "Uncompress sub component package: ${pkg_name} to directory: ${comp_user_home} failed. please check 1)disk free space 2)directory privilege 3)can be uncompressed manually or not."
							set_repeat_install_flag "COMPONENT" "${comp_id}.uncompress" "${INSTALL_FAIL_FLAG}"
							return 1
						fi
				done
			done
			
			all_pkg_file_name_list=`echo "${all_pkg_file_name_list}" | sed "s/[ \t]//g"`
			if [ "X${all_pkg_file_name_list}" = "X" ]; then
				install_log ERROR APP_INSTALL "Can't find packages for sub component: ${comp_id}."
				return 1
			fi
			
			install_log INFO APP_INSTALL "Uncompress component packages successfully."
			set_repeat_install_flag "COMPONENT" "${comp_id}.uncompress" "${INSTALL_SUCC_FLAG}"
		else
			install_log INFO APP_INSTALL "Component packages has been successfully uncompressed, so unnecessary to do again."
		fi
		temp_comp_id=${comp_id}
		#install step (2): call sub component install script
		#grant execute privileges to interface script
		if [ ! -d "${comp_user_home}/ideploy/${temp_comp_id}" ]; then
			install_log ERROR APP_INSTALL "Maybe package format is incorrect, can not find directory: ${comp_user_home}/ideploy/${comp_id}."
			set_repeat_install_flag "COMPONENT" "${comp_id}.uncompress" "${INSTALL_FAIL_FLAG}"
			return 1
		fi
		cd "${comp_user_home}"; find "./ideploy/${temp_comp_id}" -type d | xargs -n 1 -i chmod -R 750 "{}"
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Grant execute privilege to interface script failed."
			set_repeat_install_flag "COMPONENT" "${comp_id}.app.install" "${INSTALL_FAIL_FLAG}"
			return 1
		fi
									
		# before call component script, call function <env_init_cmd> to initialize component shell environment.
		# modify for INSTALL_TASK_DIR
		#if the comp_id is bme , only uncompress

		#if sub_comp_id_install.sh does not exist, it need not call
		typeset install_filename				
		install_filename="${comp_user_home}/ideploy/${temp_comp_id}/script/${comp_id}_install.sh"
		env_init_cmd "${comp_user_home}/ideploy/${temp_comp_id}/script"
		if [ $? -ne 0 ];then
			install_log ERROR APP_INSTALL "The user ${comp_user_name} env init failed."
			return 1
		fi
						
		if [ ! -f ${install_filename} ]
		then
			install_log DEBUG APP_INSTALL "the file of ${comp_id}_install.sh does not exist,so it needn't call ${comp_id}_install.sh"
		else
			su - "${comp_user_name}" -c "chmod +x ${install_filename}" 2>"${IDEPLOY_NULL}"

			su - "${comp_user_name}" -c "${install_filename} \"${comp_user_home}\" " 2>"${IDEPLOY_NULL}"
			if [ $? -ne 0 ]; then
				install_log ERROR APP_INSTALL "Installing component: ${comp_id} failed."
				set_repeat_install_flag "COMPONENT" "${comp_id}.app.install" "${INSTALL_FAIL_FLAG}"
				return 1
			fi
			
		fi
						
		#log_echo RATE ${PROGRESS_MAX}
		install_log INFO APP_INSTALL "Installing component: ${comp_id} succeeded."
		set_repeat_install_flag "COMPONENT" "${comp_id}.app.install" "${INSTALL_SUCC_FLAG}"
	done
		
	set_repeat_install_flag "COMPONENT" "${ne_name}.flag" "${INSTALL_SUCC_FLAG}"
	install_log INFO APP_INSTALL "Installing net element: ${ne_name} succeeded."
	
	copy_compinfo_to_container
    
    change_mod $ne_user_home
}

function copy_compinfo_to_container
{
         install_log INFO APP_INSTALL "begin to copy ${ne_user_home}/bin/compinfo.cfg."
                   
         typeset container_names_list=$(ls "${ne_user_home}" | grep "_container")    
         if [ "X${container_names_list}" = "X" ]
         then
              install_log ERROR APP_INSTALL "Can't find any container directory."
              return 1
         fi
                                     
         for container_name in ${container_names_list}
         do              
                   install_log INFO APP_INSTALL "Copy ${ne_user_home}/bin/compinfo.cfg to ${ne_user_home}/${container_name}/bin"          
                   if [ ! -d "${ne_user_home}/${container_name}/bin" ]; then
                            install_log ERROR APP_INSTALL "Maybe ${container_name} is incorrect, can not find directory: ${ne_user_home}/${container_name}/bin."
                            return 1
                   fi
                   
                   su - ${ne_user_name} -c "cp ${ne_user_home}/bin/compinfo.cfg ${ne_user_home}/${container_name}/bin"
                   if [ $? -ne 0 ]; then
                            install_log ERROR APP_INSTALL "Copy ${ne_user_home}/bin/compinfo.cfg to ${ne_user_home}/${container_name}/bin failed!"
                            return 1
                   fi
                   install_log INFO APP_INSTALL "Copy ${ne_user_home}/bin/compinfo.cfg to ${ne_user_home}/${container_name}/bin succeeded!"
         done
         install_log INFO APP_INSTALL "copy ${ne_user_home}/bin/compinfo.cfg succeeded."
}



################################################################################
# name	: deploy_single_app_autostart
# describe: This function is used for deploy app autostart scripts when dual type  
#		   is single.
# param1  :
#		   $1 ne_name
#		   $2 ne_user_name
# return  : 0:success
#		   1:failed
################################################################################
function deploy_single_app_autostart
{
	ne_name="$1"
	ne_user_name="$2"
	install_log "DEBUG" "APP_INSTALL" "begin to invoke deploy_single_app_autostart for NE:${ne_name}, ne user name is ${ne_user_name}."
	
	####DTS2015113009414####
	typeset after_local_path=/etc/init.d/after.local
	echo "su - ${ne_user_name} -c \"startapp all\"" >> ${after_local_path}
	########################
	
	cp "${IDEPLOY_PKG_PATH}/script/dsdp_app_autostart" /etc/init.d
	chmod 755 /etc/init.d/dsdp_app_autostart
	chkconfig dsdp_app_autostart 35
	
	mkdir -p /etc/dsdp
	user_cfg="/etc/dsdp/dsdp_user.cfg"
	if [ ! -f ${user_cfg} ];then
		touch ${user_cfg}
	fi

	comand="startapp all"
	
	sed -i "/^${ne_user_name}=/d" ${user_cfg}
	
	install_log "DEBUG" "APP_INSTALL" "begin to add \"${ne_user_name}=${comand}\" to file ${user_cfg}."
	echo "${ne_user_name}=${comand}" >> ${user_cfg}
	install_log "DEBUG" "APP_INSTALL" "end to add \"${ne_user_name}=${comand}\" to file ${user_cfg}."
	
	install_log "DEBUG" "APP_INSTALL" "end to invoke deploy_single_app_autostart."
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
	#echo ${repeat_install_status_file} ${sec_name} ${key_name}
	cfg_get_sec_key_value "${repeat_install_status_file}" "${sec_name}" "${key_name}"
	if [ $? -ne 0 ]; then
		install_log ERROR APP_INSTALL "Getting install flag of: [${sec_name}]${key_name} failed."
		return 1
	fi
	
	return 0
}

################################################################################
# name	: set_repeat_install_flag
# describe: set repeat install flag to repeat install config file.
# param1  : 
#		   $1	section name
#		   $2	key name
#		   $3	flag value
# output  : null
# rerurn  : 0:success
#		   1:failed
################################################################################
function set_repeat_install_flag
{
	if [ $# -ne 3 ]; then
		install_log DEBUG APP_INSTALL "Parameters count of function: set_repeat_install_flag error."
		return 1
	fi
	typeset sec_name="$1"
	typeset key_name="$2"
	typeset flag_value="$3"
	
	typeset comp_key_name=$(echo $key_name | awk -F\. '{print $1}')
	
	if [ "X${sec_name}" = "X" -o "X${key_name}" = "X" -o "X${flag_value}" = "X" ]; then
		install_log DEBUG APP_INSTALL "Parameters value of function:set_repeat_install_flag error, need [sec_name] [key_name] [value_name]."
		return 1
	fi
	
	if [ ${flag_value} -lt 0 -o ${flag_value} -gt 2 ]; then
		install_log DEBUG APP_INSTALL "Parameters value of function:set_repeat_install_flag error, [flag_value] should be in [0,2]."
		return 1
	fi
	
	cfg_update_sec_key_value "${repeat_install_status_file}" "${sec_name}" "${key_name}" "${flag_value}"
	if [ $? -ne 0 ]; then
		install_log DEBUG APP_INSTALL "Update install status in repeat install config file failed."
		return 1
	fi

	return 0
}

task_type="INSTALL"

if [ "X${task_type}" = "XINSTALL" ];then
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
	
	read_value "user_name"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "get user_name value failed."
		return 1		
	fi
	ne_user_name="${RETURN[0]}"
	
	read_value "user_home"
	if [ $? -ne 0 ];then
		install_log ERROR APP_INSTALL "get user_home value failed."
		return 1		
	fi
	ne_user_home="${RETURN[0]}"	
	
	for ne_name in ${local_ne_list}
	do 
		app_install "${ne_name}" "${ne_user_name}" "${ne_user_home}"
	done
fi