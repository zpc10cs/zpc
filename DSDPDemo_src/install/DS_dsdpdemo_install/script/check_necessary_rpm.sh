#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_necessary_rpm
# Description : check necessary rpm pakege 
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_necessary_rpm
{
	return 0
	typeset log_prefix="function check_os_rpm::"
	typeset current_os_rpm_list="${TMP}/tmp_check_necessary_rpm.txt"
	typeset check_os_cfg_file="${IDEPLOY_PKG_PATH}/script/check_necessary_rpm_list.ini"
	install_log "INFO" "CHECK_ENV" "begin checking necessary rpm pkg."
	grep -w "check necessary rpm success." ${current_os_rpm_list} 1>/dev/null 2>&1
	if [ $? -eq 0 ];then
		install_log "INFO" "CHECK_ENV" "${log_prefix} Check necessary rpm pkg succeed!"
		return 0
	fi
	which rpm 1>/dev/null 2>&1
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} commond \"rpm\" not found !"
		return 1
	fi
	
	if [ ! -f ${check_os_cfg_file} ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} Can't find the file ${check_os_cfg_file}."
		return 1
	fi
	typeset segment_name="rpm_all"
	typeset segment_key="service_name_list"
	#read all of [NEED-LINK-RG] from xxxall_small.ini, and get the name: db_rg ¡¢onesdp_lcapdb_rg 
	cfg_get_sec_key_value "${check_os_cfg_file}" "${segment_name}" "${segment_key}"
	if [ $? -ne 0 ];then
		install_log "DEBUG" "CHECK_ENV" "invoke cfg_get_sec_key_value  \"${check_os_cfg_file}\" \"${segment_name}\" \"${segment_key}\" error !"
		return 1
	fi
	typeset service_name_list="${RETURN[0]}"
	typeset error_num=0
	for service_name in `echo "${service_name_list}" | sed "s/,/ /g"`
	do
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} Check service \"${service_name}\"."
		cfg_get_sec_value  "${check_os_cfg_file}" "${service_name}"
		if [ $? -ne 0 ];then
			install_log "ERROR" "CHECK_ENV" "invoke cfg_get_sec_value  \"${check_os_cfg_file}\" \"${segment_name}\" error !"
			return 1
		fi
		typeset line_count=${RETNUM}
		typeset tmp_rpm_name="" 
		typeset idex=0
		while [ ${idex} -lt ${line_count} ]
		do
			typeset tmp_rpm_name="${RETURN[${idex}]}"
			typeset query_rpm_name=$(echo ${tmp_rpm_name}|awk '{print $1}')
			typeset query_rpm_versin=$(echo ${tmp_rpm_name}|awk '{print $2}')
			typeset tmp_rpm_info=$(rpm -q ${tmp_rpm_name})
			#install_log "DEBUG" "CHECK_ENV" "${log_prefix} check ${query_rpm_name} rpm pkg. "
			if [ "X${tmp_rpm_info}" = "X" ];then
				install_log "ERROR" "CHECK_ENV" "${log_prefix} rpm -q ${query_rpm_name} FAILED!"
				((error_num++))
				((idex++))
				continue
			elif [ "X${query_rpm_versin}" != "X" ];then
				#perl-5.10.0-64.47.8  =>version 5.10.0
				typeset tmp_rpm_version=$(echo ${tmp_rpm_info}|awk -F- '{print $(NF-1)}')
				
				if [ "X${tmp_rpm_version}" = "X" ];then
					install_log "ERROR" "CHECK_ENV" "${log_prefix} the version of ${query_rpm_name} is empty!"
					((error_num++))
					((idex++))
					continue
				else
					install_log "DEBUG" "CHECK_ENV" "${log_prefix} check ${query_rpm_name} version "
					typeset -i v_index=1
					typeset -i v_all_index=$(echo ${query_rpm_versin}| awk -F. '{print NF}' )
					#echo "v_all_index=${v_all_index}"
					#compare version
					while [ ${v_index} -le ${v_all_index} ]
					do
						typeset -i query_v=$(echo ${query_rpm_versin} |awk -F. -vidx=${v_index} '{print $idx}' )
						typeset -i tmp_v=$(echo ${tmp_rpm_version} |awk -F. -vidx=${v_index} '{print $idx}' )
						if [ ${tmp_v} -lt ${query_v} ];then
							install_log "ERROR" "CHECK_ENV" "${log_prefix} the version of ${query_rpm_name} is ${tmp_rpm_version} lower than required ${query_rpm_versin} !"
							((error_num++))
							break 
						fi
						((v_index++))
					done
				fi
			fi
			((idex++))
		done
		
	done
	
	if [ ${error_num} -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "${log_prefix} Check necessary rpm pkg error !"
		return 1
	fi
	echo "check necessary rpm success." > ${current_os_rpm_list}
 	install_log "INFO" "CHECK_ENV" "${log_prefix} Check necessary rpm pkg complete."
	return 0
}
