#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_disk_free_space
# Description : check the free disk is enough or not.
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_disk_free_space
{
	typeset log_prefix="function check_disk_free_space::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
		  
	typeset -i subCompe_count=0
	typeset -i i=0
	typeset -i k=0
	typeset -i req_usr_free_disk=0
	typeset -i req_df_disk=0
	typeset -i usr_disk=0
	typeset username=""
	#the subComp array 
	typeset subComp=""
	typeset -i flag=0
		
	#get user array of the current machine
	get_user_list
	if [ $? -ne 0 ]; then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_special_user failed."
		install_log "ERROR" "CHECK_ENV" "Checking disk free space failed."
		return 1
	fi
	
	typeset -i usercount="${RETNUM}"
	
	#get the user list
	while [ ${i} -lt ${usercount} ]
	do
		typeset user_name[${i}]="${RETURN[${i}]}"
		((i=i+1))	
	done
	
	#reset the i = 0
	i=0
 	#get subcomponents
 	while [ ${i} -lt ${usercount} ]
 	do 			
 		username="${user_name[${i}]}"
 		
 		#get the subcomponent array by the user
 		get_subComp_by_user "${username}"
 		if [ $? -ne 0 ]; then
 			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_subComp_by_user ${username} failed."
 			install_log "ERROR" "CHECK_ENV" "Getting the ${username} user component list failed."
 			return 1
 		fi
 		
 		k=0
 		
 		subCompe_count="${RETNUM}"
 		while [ ${k} -lt ${subCompe_count} ]
 		do
 			typeset subComp[${k}]="${RETURN[${k}]}"
 			((k=k+1))
 		done
 		
 		#reset k =0 
 		k=0
 		
 		#get request free disk by subComponent 		
 		while [ ${k} -lt ${subCompe_count} ]
 		do
 			typeset tmp_name="${subComp[${k}]}"
 			typeset subComp_name=`echo "${tmp_name}" | ${AWK} -F+ '{print $1}'`
 			typeset -i num=`echo "${tmp_name}" | ${AWK} -F+ '{print $2}'`			
 			#get free disk
 			read_value "${env_std_cfg}" "req_free_disk_${subComp_name}"
 			if [ $? -ne 0 ]; then
 				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value ${env_std_cfg} req_free_disk_${subComp_name[${k}]} error."
        		install_log "ERROR" "CHECK_ENV" "Reading config item req_free_disk_${subComp_name} from ${env_std_cfg} failed." 
        		return 1
    		fi
    		
    		#get the disk space of specify subcomponent
    		typeset -i req_component_disk="${RETURN[0]}"
    		#the unit of space is K
    		((req_usr_free_disk=req_component_disk*num*1024))
    		
    		#add all subcomponent space
    		((usr_disk=usr_disk+req_usr_free_disk))
    		
    		#get the next subcomponent space	
			((k=k+1))
 		done
 		
 		#create the req_usr_disk array,the index is from the user index,so the req_usr_disk[${i}] image the disk space of user[${i}]
 		typeset req_usr_disk[${i}]="${usr_disk}"
 		
 		#reset the usr_disk variable
 		usr_disk=0
 		
 		#get the next user subcomponent
 		((i=i+1)) 		
 	done
 	
 	#reset index i = 0
	i=0
	#get the space of current machine
	df | ${SED} -n '2,$p' | ${AWK} '{if(NF>=5) print $NF}' > df_tmp
	while read lines
	do
		#get system free disk
 		typeset df_free_disk=`df -k ${lines} | ${SED} -n '$p' | ${AWK} '{if(NF==6) print $(NF-2);if(NF==5) print $(NF-2)}'`
 		
 		install_log "INFO" "CHECK_ENV" "The mount(${lines}) free disk is ${df_free_disk}K"
 		
 		#get require free disk in mount
 		#NOTE:magbe some user share the same mount,it is incorrect that any user disk space check failed and the other user continue count
 		#so when any user check failed the step will be cancelled
		while [ ${i} -lt ${usercount} ]
		do
			typeset usrflag="${user_name[${i}]}"
			
			#get user home			
			read_value "${usrflag}_user_home"
			if [ $? -ne 0 ]; then
				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value ${usrflag}_user_home error."
				install_log "ERROR" "CHECK_ENV" "Getting ${usrflag}_user_home failed."
				return 1
			fi
			
			typeset usrhome="${RETURN[0]}"
			
			#get the disk mount dir that the user home belong to						
 			check_mount_dir "${usrhome}"
 			if [ $? -ne 0 ]; then
 				install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_mount_dir ${usrhome} failed."
 				install_log "ERROR" "CHECK_ENV" "Getting the ${usrhome} mount failed."
 				return 1
 			fi
 			
 			#the variable is mount dir
 			typeset dftype="${RETURN[0]}"
 			typeset usr_tmp="${req_usr_disk[${i}]}"
 		
 			#if the user dir share the same mount then add the require space
 			if [ "x${dftype}" = "x${lines}" ]
 			then
 				((req_df_disk=req_df_disk+usr_tmp)) 										
 			fi
 		    	  
 			((i=i+1))
		done
		
		install_log "INFO" "CHECK_ENV" "The mount(${lines}) require free disk is ${req_df_disk}K."
			 
		if [ ${df_free_disk} -lt ${req_df_disk} ]
		then
			install_log "ERROR" "CHECK_ENV" "Checking the home of root space failed,the free disk is ${df_free_disk}, require at least ${req_df_disk} free disk."
			((flag=flag+1))
			#continue check the next mount
			continue
		fi
		
		#initial the variable
		req_df_disk=0
		i=0
	 done < df_tmp
	 
	 #delete the temp file
	 rm -rf df_tmp
	 
	 if [ ${flag} -gt 0 ]; then
		return 1
	 fi
}

################################################################################
# Function    : get_user_list 
# Description : get user array of the current machine;if standby,don't include share disk user
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function get_user_list
{
	typeset log_prefix="function get_user_list::"
	
	typeset -i i=0
	typeset -i k=0
	
	typeset comp_arry_count=0
	
	if [ "x${host_type}" = "xstandby"  ]; then
		#get the component list that the component install in svg		
		#get_svg_component_list
		#if [ $? -ne 0 ]; then
		#	install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_svg_component_list failed."
		#	install_log "ERROR" "CHECK_ENV" "Getting the component list that the component install in svg failed."
		#	return 1
		#fi
		
		typeset share_count=0
		typeset -i share_index=0
		typeset share_tmp=""
		typeset -i comp_count=1
		typeset -i share_flag=0
		
		#get component,but don't include the component that install in svg
		while [ ${comp_count} -le ${comp_arr[0]} ]
		do
			typeset comp_tmp="${comp_arr[${comp_count}]}"
			
			#if the component install in svg,
			while [ ${share_index} -lt ${share_count} ]
			do				
				share_tmp="${RETURN[${share_index}]}"
				if [ "x${comp_tmp}" = "x${share_tmp}" ]; then
					share_flag=1
					break
				fi
				
				((share_index=share_index+1))
			done
			share_index=0
			
			#if share_flag=0,show the component don't install in svg
			if [ ${share_flag} -eq 0 ]; then				
				typeset comp_arry[${comp_arry_count}]="${comp_tmp}"
				((comp_arry_count=comp_arry_count+1))
			fi
			
			share_flag=0
			((comp_count=comp_count+1))
		done
	else
		
		k=1
		while [ ${k} -le ${comp_arr[0]} ]
		do
			typeset comp_arry[${comp_arry_count}]="${comp_arr[${k}]}"
			((comp_arry_count=comp_arry_count+1))
			((k=k+1))
		done				
	fi
	
	#get user array of the current machine
	typeset -i comp_index=0
	typeset -i user_count=0
	typeset -i user_pos=0
	typeset user_arry[0]=""
	share_flag=0
	
	while [ ${comp_index} -lt ${comp_arry_count} ]
	do
		typeset comp_name="${comp_arry[${comp_index}]}"
		
		#get the user collection of the specify component
		get_user_by_component "${comp_name}"
		
		if [ $? -ne 0 ]
		then
			install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke get_user_by_component ${comp_name} error ."
			install_log "ERROR" "CHECK_ENV" "Getting the user collection of the specify component failed."
			return 1
		fi
		
		while [ ${i} -lt ${RETNUM} ]
		do
			typeset tmp="${RETURN[${i}]}"
			#check the user whether exist in the user_arr
			if [ "${comp_index}" -eq 0 ]; then
				user_arry[0]=${tmp}
				user_count=1
			else
				while [ ${user_pos} -lt ${user_count} ]
				do
					typeset usr_tmp="${user_arry[${user_pos}]}"
					if [ "x${tmp}" = "x${usr_tmp}" ]; then
						share_flag=1
						break
					fi
					
					((user_pos=user_pos+1))
				done
				user_pos=0
				
				if [ ${share_flag} -eq 0 ]; then					
					user_arry[${user_count}]="${tmp}"
					((user_count=user_count+1))					
				fi
				share_flag=0				
			fi
			
			((i=i+1))
		done
		((comp_index=comp_index+1))
		i=0
	done
	
	i=0
	user_pos=0	
	while [ ${i} -lt ${user_count} ]
	do
		RETURN[${i}]="${user_arry[${i}]}"
		((i=i+1))
		
	done
	
	RETNUM="${user_count}"
}

################################################################################
# Function    : check_mount_dir
# Description : check the disk mount dir
# parameter list:null
# Output      : RETURN[0]	the mount dir
# Return      : 0 success
#               1 failed
################################################################################
function check_mount_dir
{
	typeset log_prefix="function check_mount_dir::"
	
	if [ $# -ne 1 ]
	then
		install_log "DEBUG" "CHECK_ENV" "${log_prefix} the input parameter number is incorrect."
        return 1
	fi
		
	typeset dir=$1
    typeset df_cmd="df"

    ${df_cmd} | awk '{print $NF}' > ${mout_temp_file}
        
    typeset is_exist_mout="/"
    while [ "${dir}" != "/" ]
    do
        while read line
        do
        	#check the dir path whether in mount
            if [ "X${dir}" = "X${line}" ]; then
                is_exist_mout="${line}"
                break 2
            fi
        done <${mout_temp_file}
        
        #get the parent file path
        dir=`dirname ${dir}`       
    done    
    
    RETURN[0]="${is_exist_mout}"
   
}



