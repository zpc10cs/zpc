#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_install_package
# Description : check the install package whether deploy in current machine
# parameter list: null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_install_package
{
	typeset log_prefix="function check_install_package::"
	
	typeset -i comp_count="${comp_arr[0]}"
	typeset -i comp_index=1
	typeset -i pkg_count=0
	typeset -i pkg_index=0
	typeset pkg_name=""
	typeset -i flag=0
	
	while [ ${comp_index} -le ${comp_count} ]
	do
		install_log "INFO" "CHECK_ENV" "Begin to check ${comp_arr[${comp_index}]} component package."
		
		#get the pkg list of component
		get_package_by_component "${comp_arr[${comp_index}]}"
		
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_subComp_by_component ${comp_arr[${comp_index}]} failed."
			install_log "ERROR" "CHECK_ENV" "Checking package failed."
			install_log "INFO" "CHECK_ENV" "Finish checking ${comp_arr[${comp_index}]} component package."
			
			((flag=flag+1))
			#continue check next component
			((comp_index=comp_index+1))
			continue
		fi
		
		pkg_count="${RETNUM}"
		
		while [ ${pkg_index} -lt ${pkg_count} ]
		do
			pkg_name="${RETURN[${pkg_index}]}"
			typeset pkg_names_list=`(cd "${PKG_PATH}"; ls | sed -n "/^${pkg_name}$/p")`
			if [ "x${pkg_names_list}" = "x" ]
			then
	 		 	install_log "ERROR" "CHECK_ENV" "The package ${pkg_name} is not exist."
	 		 	((flag=flag+1))
	 		fi
	 		
	 		((pkg_index=pkg_index+1))
		done
		install_log "INFO" "CHECK_ENV" "Finish checking ${comp_arr[${comp_index}]} component package."
		pkg_index=0
		((comp_index=comp_index+1))
	done
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}



