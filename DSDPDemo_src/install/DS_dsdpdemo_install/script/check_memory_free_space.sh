#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_memory_free_space
# Description : check the free memory is enough or not.
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_memory_free_space
{	
	typeset log_prefix="function check_memory_free_space::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
	
	#get the free memory of current machine
	typeset free_memory=`vmstat | sed -n '$p' | awk '{print $4}'`
	
	install_log "INFO" "CHECK_ENV" "The system free memory is ${free_memory}K."
	
	typeset i=1
	typeset k=0
	typeset req_memory=0
	
	#cycle get the require total memory of all components
	while [ ${i} -le ${comp_arr[0]} ]
	do
		component_name="${comp_arr[${i}]}"
		
		#get subcomponents by component
		get_subComp_by_component "${component_name}"
		if [ $? -ne 0 ]; then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_subComp_by_component ${component_name} error!"
			install_log "ERROR" "CHECK_ENV" "Getting the component info failed."
			return 1
		fi
		
		#create subComponent array
		typeset subComp_count=${RETNUM}
		while [ ${k} -lt ${subComp_count} ]
		do
			typeset subComp_arr[${k}]="${RETURN[${k}]}"
			((k=k+1))
		done
		
		#get the total memory of all subcomponents
		k=0
		while [ ${k} -lt ${subComp_count} ]
		do
			subComp_name="${subComp_arr[${k}]}"
								
			#get free memory by subcomponent
			read_value "${env_std_cfg}" "req_free_memory_${subComp_name}"
			if [ $? -ne 0 ]; then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value ${env_std_cfg} req_free_memory_${subComp_name} error !"
				install_log "ERROR" "CHECK_ENV" "Getting the ${subComp_name} require memory value failed."
				return 1
			fi
			
			typeset req_subComp_memory=${RETURN[0]}			
			install_log "INFO" "CHECK_ENV" "The ${subComp_name} require free memory is ${req_subComp_memory}M."
			
			((req_memory=req_memory+req_subComp_memory))
			
			((k=k+1))
		done
		k=0
		((i=i+1)) 				
	done
	
	((req_memory=req_memory*1024))
	
	install_log "INFO" "CHECK_ENV" "The require free memory totals ${req_memory}K"
			
	if [ ${free_memory} -lt ${req_memory} ]
	then
		install_log "ERROR" "CHECK_ENV" "There is not enough free memory. It require ${req_memory}K free memory, but actually there is only ${free_memory}K."
		return 1
	fi
}


