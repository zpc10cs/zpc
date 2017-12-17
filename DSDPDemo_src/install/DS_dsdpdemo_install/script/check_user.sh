#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Function    : check_user
# Description : check the user that install need have exist or not.
# parameter list:null
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_user
{
	typeset log_prefix="function check_user::"
	#typeset log_suffix="more detail of fail info please to see ${log_file}."
	
	typeset -i user_idx=1
	typeset user_tmp=""
		
	typeset -i flag=0

	
    read_value "user_home"
    if [ $? -ne 0 ]; then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value user_config.$idx.user_home failed!"
        install_log "ERROR" "CHECK_ENV" "Reading user_config.$idx.user_home value failed."
        ((flag=flag+1))
        #check the next user info
        ((user_idx=user_idx+1))
        continue
    fi
    user_home="${RETURN[0]}"
    
    read_value "user_name"
    if [ $? -ne 0 ]; then
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke read_value user_name failed!"
        install_log "ERROR" "CHECK_ENV" "Reading user_name value failed."
        ((flag=flag+1))
        #check the next user info
        ((user_idx=user_idx+1))
    fi
    user_name="${RETURN[0]}"
    
    check_user_info "${user_name}" "${user_home}"
    if [ $? -ne 0 ]
    then
        ((flag=flag+1))
        install_log "DEBUG" "CHECK_ENV" "${log_prefix} invoke check_user_info ${user_name} ${dm_type} ${user_home} error."
    fi


	#if /usr/bin/sh is not exist,maybe the install step will be failed because of using the /usr/bin/sh
	if [ ! -f /usr/bin/sh ]
	then
		if [ -f /bin/sh ]
		then
			ln -sf /bin/sh /usr/bin/sh
			if [ $? -ne 0 ]	
			then
				install_log "ERROR" "CHECK_ENV" "execute \"ln -sf /bin/sh /usr/bin/sh \" command failed."
				((flag=flag+1))
			fi
		else
			install_log "ERROR" "CHECK_ENV" "the source file /bin/sh is not exist,so don't create link to /usr/bin/sh."
			((flag=flag+1))
		fi
	fi
	
	if [ ${flag} -gt 0 ]; then
		return 1
	fi
}

################################################################################
# Function    : check_user_info
# Description : check the user whether exist or not
# parameter list:$1 user_name
#				 $2 dm_type[single|coldDualHost|hotDualHost]
#				 $3 user_home
# Output      : None
# Return      : 0 success
#               1 failed
################################################################################
function check_user_info
{
	typeset log_prefix="function check_user_info::"
		
	typeset user_name="$1"
	typeset user_home="$2"
	
	typeset -i flag=0
    user_home=`echo "${user_home}" | ${SED} 's/\/$//'`
	typeset local_user_name_exist=`${AWK} -F: '{print $1}' /etc/passwd | ${GREP} ^${user_name}$`
    if [ "x${local_user_name_exist}" != "x" ];then
        install_log "WARN" "CHECK_ENV" "the user name \"${user_name}\" already exists in local machine,please check."
        typeset local_user_name_exist=`cat /etc/passwd | ${GREP} ^${user_name}|awk -F: '{print $6}'|${GREP} ^${user_home}`
        if [ "x${local_user_name_exist}" = "x" ];then
            install_log "ERROR" "CHECK_ENV" "the user home with user name must be a pair."
            ((flag=flag+1))
        fi
    fi
	#replace user_home's path separator \ to /
	
	#the user home must begin with /
	typeset is_slash_begin=`echo ${user_home} | ${SED} -n "s#^[ \t]*##gp" | ${GREP} ^/`
	if [ "${is_slash_begin}" = "x" ]
	then
		install_log "ERROR" "CHECK_ENV" "the user home ${user_home} must use absolute path."
		((flag=flag+1))
	fi
	#the user home can't be exist
	if [ "X${task_type}" = "XUPDATE" ];then
		if [ ! -d ${user_home} ];then
			install_log "WARN" "CHECK_ENV" "the user home ${user_home} does not exist in current machine."
			((flag=flag+1))
		fi
	elif [ "X${task_type}" = "XINSTALL" ];then
		if [ -d ${user_home} ];then
			install_log "WARN" "CHECK_ENV" "the user home ${user_home} has already exist in current machine."			
		fi
	fi
	
	typeset un_dir_lists="/ /opt /home /usr /var /tmp /boot"
	
	for list in ${un_dir_lists}
	do 
		if [ "X${user_home}" = "X${list}"  ];then
			install_log "ERROR" "CHECK_ENV" "the user home ${user_home} must not be / /opt /home /usr /var /tmp /boot."		
			((flag=flag+1))	
			break
		fi
	done
	
	#add by x00193019 date.20130129 .check the user's parent directory owner and right, it must be root 755 .
	typeset parent_dir=$(dirname ${user_home})
	if [ -d ${parent_dir} ]
	then
		typeset tmp_pdir_info=$(ls -ld ${parent_dir})
		typeset tmp_pdir_owner=$(echo ${tmp_pdir_info}|awk '{print $3 }')
		typeset tmp_pdir_right=$(echo ${tmp_pdir_info}|awk '{print $1 }')
		
		if [ "X${tmp_pdir_owner}" = "X" -o "X${tmp_pdir_right}" = "X" ];then
			install_log "ERROR" "CHECK_ENV" "get the user parent home \"${parent_dir}\" info failed."
			((flag=flag+1))
		else
			if [ "X${tmp_pdir_owner}" != "Xroot" -o "X${tmp_pdir_right}" != "Xdrwxr-xr-x" ];then
				install_log "ERROR" "CHECK_ENV" "check ${user_name}'s parent dir \"${parent_dir}\" failed."
				install_log "DEBUG" "CHECK_ENV" "parent dir \"${parent_dir}\" must be root 755."
				((flag=flag+1))
			fi
		fi
		
	fi
	#add by x00193019 date.20130129 end
	
	#local user_name can't be exist
	
	
	if [ ${flag} -gt 0 ]
	then
		return 1
	fi
}


