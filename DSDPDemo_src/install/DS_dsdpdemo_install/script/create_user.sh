#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# Name       : create_user.sh
# Describe   : add user.
# Date       : 2009-02-13
# Functions  :
#              create_app_run_user        create run user for application.
#              create_dual_user           create dual host application run user.
#              check_user_is_created      check the opposite machine whether create the user.
#              tell_the_other_generating_uid   tell the opposite machine the one is generating uid.
#              generating_uid             generate the uid of user.
#              tell_the_other_uid         Tell the opposite machine generated uid of this user.
#              read_uid_from_opposite     Read the opposite machine generated uid.
#              create_single_user         Create single machine user.
#              convert_gid_to_groupname   Convert gid to group name.
################################################################################

################################################################################
# name    : create_app_run_user
# describe: create run user for application.
# input   : user_name
#           user_password
#           user_home
#           group_id(the user's gid)
#           float_ip(dual host must have)
#           opposite_ip(dual host must have)
#           idx(idx is current float_ip in the list of float_ip 's position)
# output  : null
# rerurn  : 0 success
#           1 failed
# invoker : dsdp_install.sh
################################################################################
function create_app_run_user
{

	typeset user_name="${1}"
	typeset user_password="${2}"
	typeset user_home="${3}"
	typeset group_id="${4}"
	typeset idx="${7}"
	typeset taskid="${TASK_NUM}"
	
	create_single_user "${user_name}" "${user_password}" "${group_id}" "${idx}" "${user_home}"
	typeset rt=$?
	rm -f "/tmp/tmp_generating_uid_local_${idx}_${taskid}"
	rm -f "/tmp/generating_uid_local_${idx}_${taskid}"
	
	if [ ${rt} -ne 0 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "Creating user ${user_name} failed!"
		return 1
	fi
	return 0

}
################################################################################
# name    : create_dual_user
# describe: create dual host user 
# input   : user_name
#           user_password
#           user_home
#           opposite_ip(dual host must have)
#           float_ip(dual host must have)
#           idx(idx is current float_ip in the list of float_ip 's position)
#           group_id(the user's gid)
# output  : null
# rerurn  : NULL
# invoker : 
################################################################################
function create_dual_user
{
	typeset user_name="${1}"
	typeset user_password="${2}"
	typeset user_home="${3}"
	typeset group_id="${4}"
	typeset float_ip="${5}"
	typeset opposite_ip="${6}"
	typeset idx="${7}"
	
	typeset taskid=$TASK_NUM
	check_user_is_created "${float_ip}" "${opposite_ip}" "${idx}" "${user_name}" "${user_home}" "${group_id}" "${user_password}"
	typeset rt=$?
	if [ ${rt} -eq 1 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "Creating dual user failed!"
		return 1
	elif [ ${rt} -eq 2 ]
	then 
		install_log "INFO" "DSDP_INSTALL" "Creating dual user succeed!"
		return 0
	fi
	
	typeset opposite_create_user_file="/tmp/tmp_from_opposite_machine_${user_name}_${float_ip}_${idx}_${taskid}"
	typeset remote_uid_file="/tmp/etc_passwd_from_opposite_ip_${float_ip}_${idx}_${taskid}"
	typeset uid_file="/tmp/uid_from_opposite_${user_name}_${float_ip}_${idx}_${taskid}"
	#check opposite machine whether generated uid,or is generating uid. If not generate uid ,this machine generating it!
	if [ ! -f "${opposite_create_user_file}" ]
	then
		#tell the other this machine is generating uid.
		tell_the_other_generating_uid "${opposite_ip}" "${float_ip}" "${idx}" "${user_name}"
		if [ $? -ne 0 ]
		then 
			install_log "ERROR" "DSDP_INSTALL" "Announcing this machine is generating uid of ${user_name} failed!"
			return 1
		fi
		
		#generate a vaild uid
		generating_uid "$float_ip" "$idx"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating uid failed!"
			return 1
		fi 
		
		typeset local_uid=${RETURN[0]}
		
		#tell the other machine generated uid.
		tell_the_other_uid "${user_name}" "${local_uid}" "${float_ip}" "${opposite_ip}" "${idx}"
		if [ $? -ne 0 ]
		then 
			install_log "ERROR" "DSDP_INSTALL" "Announcing the user of ${user_name} 's uid failed!"
			return 1
		fi
		
		#add local user!

		convert_gid_to_groupname "${group_id}"
		if [ $? -ne 0 ]
		then 
			return 1
		fi
		typeset group_name=${RETURN[0]}
		
		user_create_user "${user_name}" "${user_home}" "/usr/bin/csh" "${group_name}" "${local_uid}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Adding user failed"
			return 1 
		fi

		#change user's password
		user_change_passwd "${user_name}" "${user_password}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Changing the password of ${user_name} failed"
			return 1 
		fi
		return 0
	else		
		#get the other machine generated uid!
		read_uid_from_opposite "${user_name}" "${float_ip}" "${idx}"
		if [ $? -ne 0 ]
		then
			install_log "INFO" "DSDP_INSTALL" "The opposite machine is generating uid ,so waiting 3 seconds"
			sleep 3
			typeset -i read_uid_number=0
			while [ ${read_uid_number} -lt 5 ]
			do
				read_uid_from_opposite "${user_name}" "${float_ip}" "${idx}"
				if [ $? -ne 0 ]
				then
					install_log "INFO" "DSDP_INSTALL" "The opposite machine is generating uid ,so waiting 3 seconds"
					sleep 3
					((read_uid_number=read_uid_number+1))
				else 
					break
				fi
				
				if [ ${read_uid_number} -eq 4 ]
				then 
					install_log "ERROR" "DSDP_INSTALL" "The opposite machine generating uid failed, so quit!"
					return 1 
				fi
			done
		fi
		
		uid="${RETURN[0]}"
		
		#add local user!
		convert_gid_to_groupname "${group_id}"
		if [ $? -ne 0 ]
		then 
			return 1
		fi
		typeset group_name=${RETURN[0]}
		
		user_create_user "${user_name}" "${user_home}" "/usr/bin/csh" "${group_name}" "${uid}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Adding user failed"
			return 1 
		fi

		user_change_passwd "$user_name" "${user_password}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Changing the password failed"
			return 1 
		fi
		return 0 
	fi
}

################################################################################
# name    : check_user_is_created
# describe: Check the dual host machine user whether created on the two machine.
#            If the current machine has created user and the uid is free on the 
#            other machine, return 2. If the opposite machine has created user, 
#            and the uid is free on this machine, using the uid created user and 
#            return 2. If both machine has created user and all the users' information
#            are same,return 2. If both machine have not created user, return 0.
#            or return 1.
# input   : float_ip                      the dual host 's float_ip
#           opposite_ip                   the machine machine's actual ip.
#           idx                           idx is current float_ip in the list of float_ip 's position
#           user_name                     user's name
#           user_home                     user's home
#           group_id                      the gid of this user.
#           user_passwd                   user password.      
# output  : null
# rerurn  : 0                             need create user.
#           1                             create user failed
#           2                             create user succeed.
# invoker : 
#          create_dual_user
################################################################################
function check_user_is_created
{
	typeset float_ip="${1}"
	typeset opposite_ip="${2}"
	typeset idx="${3}"
	typeset user_name="${4}"
	typeset user_home="${5}"
	typeset group_id="${6}"
	typeset user_passwd="${7}"
	typeset taskid="${TASK_NUM}"
	typeset user_shell_1=/usr/bin/csh
	typeset user_shell_2=/bin/csh
	
	typeset remote_uid_file="/tmp/etc_passwd_from_opposite_ip_${float_ip}_${idx}_${taskid}"
	
	typeset tell_file="/tmp/tmp_from_opposite_machine_${user_name}_${float_ip}_${idx}_${taskid}"
	typeset uid_file="/tmp/uid_from_opposite_${user_name}_${float_ip}_${idx}_${taskid}"
	scp "$opposite_ip:/etc/passwd" "${remote_uid_file}" 1>/dev/null 2>&1
	if [ $? -ne 0 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "Copying /etc/passwd from opposite machine failed!"
		return 1
	fi
	
	typeset user_exist_in_remote=`awk -F: -v username=$user_name -v userhome=$user_home -v gid=$group_id -v shell1=$user_shell_1 -v shell2=$user_shell_2 '
								{
									if ( $1 == username )
									{
										if($6 == userhome && $4 == gid && ($7 == shell1 || $7 == shell2))
										{
											print $3 
										}
										else
										{
											print -1
										}
										exit(0)
									}
								}' "${remote_uid_file}"`
	
	
	typeset remote_flag=1
	typeset remote_uid=-1
	if [ "x${user_exist_in_remote}" = "x" ]
	then
		remote_flag=0
	elif [ ${user_exist_in_remote} -eq "-1" ]
	then 
		remote_flag=-1
	else
		remote_uid=${user_exist_in_remote}
	fi 
	
	typeset user_exist_in_local=`awk -F: -v username=$user_name -v userhome=$user_home -v gid=$group_id -v shell1=$user_shell_1 -v shell2=$user_shell_2 '
								{
									if ( $1 == username )
									{
										if($6 == userhome && $4 == gid && ($7 == shell1 || $7 == shell2))
										{
											print $3 
										}
										else
										{
											print -1
										}
										exit(0)
									}
								}' "/etc/passwd"`
	
	typeset local_flag=1
	typeset local_uid=-1
	if [ "x${user_exist_in_local}" = "x" ]
	then
		local_flag=0
	elif [ "${user_exist_in_local}" -eq "-1" ]
	then 
		local_flag=-1
	else
		local_uid="${user_exist_in_local}"
	fi 
	
	if [ remote_flag -eq 0 -a local_flag -eq 0 ]
	then 
		return 0
	elif [ remote_flag -eq -1 -o local_flag -eq -1 ]
	then
		return 1
	elif [ local_flag -eq 1 -a remote_flag -eq 1 -a remote_uid -eq local_uid ]
	then 
		return 2
	elif [ local_flag -eq 1 -a remote_flag -eq 1 -a remote_uid -ne local_uid ]
	then 
		return 1
	elif [ local_flag -eq 1 -a remote_flag -eq 0 ]
	then 
		is_uid_exist=`awk -F: -v uid=$local_uid '
		{
			if ($3 == uid)
			{
				print 1
				exit(0)
			}
		}' "${remote_uid_file}"`
		
		if [ "x${is_uid_exist}" != "x" ]
		then 
			install_log "ERROR" "DSDP_INSTALL" "Local user's uid have used by remote machine!"
			return 1 
		fi
		
		# tell_the_other_uid "$user_name" "$local_uid" "$float_ip" "${opposite_ip}" "$idx" "$taskid"
		# if [ $? -ne 0 ]
		# then 
			# install_log "ERROR" "DSDP_INSTALL" "Announcing the other machine uid failed"
			# return 1 
		# fi		
		return 2 
	elif [ local_flag -eq 0 -a remote_flag -eq 1 ]
	then		
		convert_gid_to_groupname "${group_id}"
		if [ $? -ne 0 ]
		then 
			return 1
		fi
		typeset group_name="${RETURN[0]}"
		
		user_create_user "${user_name}" "${user_home}" "/usr/bin/csh" "${group_name}" "${remote_uid}" 1>/dev/null 2>&1
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Creating local user ${user_name} failed!"
			return 1 
		fi
		
		user_change_passwd "${user_name}" "${user_passwd}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Changing user ${user_name} password failed!"
			return 1 
		fi
		
		return 2 
	fi
}

################################################################################
# name    : tell_the_other_generating_uid
# describe: Telling the other machine this one is generating uid of this user.
# input   : 
#           opposite_ip                   the machine machine's actual ip.
#           float_ip                      the dual host 's float_ip
#           idx                           idx is current float_ip in the list of float_ip 's position    
# output  : null
# rerurn  : 0                             success
#           1                             failed
# invoker : 
#          create_dual_user
################################################################################
function tell_the_other_generating_uid
{
	typeset opposite_ip="${1}"
	typeset float_ip="${2}"
	typeset idx="${3}"
	typeset user_name="${4}"
	typeset taskid="${TASK_NUM}"
	
	typeset tell_file="/tmp/tmp_from_opposite_machine_${user_name}_${float_ip}_${idx}_${taskid}"
	echo "$user_name 1" > "tmp_$$"
	scp "tmp_$$" "$opposite_ip:${tell_file}" 1>/dev/null 2>&1
	if [ $? -ne 0 ]
	then 
		return 1
	fi
	rm -f "tmp_$$"
	return 0
}

################################################################################
# name    : generating_uid
# describe: generate the user's uid.
# input   : 
#           float_ip                      the dual host 's float_ip
#           idx                           idx is current float_ip in the list of float_ip 's position    
#                                         or idx is current ne in the machine's position   
# output  : 
#            the uid of generated.
# rerurn  : 
#           0                             success
#           1                             failed
# invoker : 
#          create_dual_user
#          create_single_user
################################################################################
function generating_uid
{
	typeset float_ip="${1}"
	typeset idx="${2}"
	typeset taskid="${TASK_NUM}"
	
	typeset remote_uid_file="/tmp/etc_passwd_from_opposite_ip_${float_ip}_${idx}_${taskid}"
	typeset tmp_generating_uid_file="/tmp/tmp_generating_uid_${float_ip}_${idx}_${taskid}"
	typeset generating_uid_file="/tmp/generating_uid_${float_ip}_${idx}_${taskid}"
	
	if [ "-${float_ip}" != "-" ]
	then
		typeset -i base_uid=3500
		typeset -i segment=50
		((begin_uid=base_uid+segment*idx))
		if [ ${begin_uid} -ge 4000 ];then
			install_log "ERROR" "DSDP_INSTALL" "Generating user uid failed, it's more than the range from 3000 to 4000!"
			return 1
		fi
		awk -F: -v b_uid=${begin_uid} -v sgmt=${segment} '
		BEGIN {e_uid = b_uid + sgmt}
		{
			if ( $3 > b_uid && $3 <= e_uid)
			{
				print $3
			}
		}' "${remote_uid_file}" > "${tmp_generating_uid_file}"
		
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating remote uid file failed!"
			return 1 
		fi
		
		awk -F: -v b_uid=${begin_uid} -v sgmt=${segment} '
		BEGIN {e_uid = b_uid + sgmt}
		{
			if ( $3 > b_uid && $3 <= e_uid)
			{
				print $3
			}
		}' "/etc/passwd" >> "${tmp_generating_uid_file}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating local uid file failed!"
			return 1 
		fi
		
		sort -nu "${tmp_generating_uid_file}" > "${generating_uid_file}"
		echo "" >> "${generating_uid_file}"
		
		typeset user_uid=`awk -v b_uid=$begin_uid '
				{
					current_uid = b_uid + NR
					if ($0 != current_uid)
					{
						print current_uid
						exit(0)
					}
				}' "${generating_uid_file}"`
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating uid failed!"
			return 1 
		fi
		RETURN[0]=${user_uid}
		return 0
	else
		typeset -i base_uid=3000
		typeset -i segment=50
		
		typeset tmp_generating_local_uid_file="/tmp/tmp_generating_uid_local_${idx}_${taskid}"
		typeset generating_local_uid_file="/tmp/generating_uid_local_${idx}_${taskid}"
		((begin_uid=base_uid+segment*idx))
		if [ ${begin_uid} -ge 4000 ];then
			install_log "ERROR" "DSDP_INSTALL" "Generating user uid failed, it's more than the range from 3000 to 4000!"
			return 1
		fi
		awk -F: -v b_uid=${begin_uid} -v sgmt=${segment} '
		BEGIN {e_uid = b_uid + sgmt}
		{
			if ( $3 > b_uid && $3 <= e_uid)
			{
				print $3
			}
		}' "/etc/passwd" >> "${tmp_generating_local_uid_file}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating local uid file failed!"
			return 1 
		fi
		
		
		sort -nu "${tmp_generating_local_uid_file}" > "${generating_local_uid_file}"
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Sorting local uid file failed!"
			return 1 
		fi
		
		echo "" >> "${generating_local_uid_file}"
		typeset user_uid=`awk -v b_uid=$begin_uid '
				{
					current_uid = b_uid + NR
					if ($0 != current_uid)
					{
						print current_uid
						exit(0)
					}
				}' "${generating_local_uid_file}"`
		if [ $? -ne 0 ]
		then
			install_log "ERROR" "DSDP_INSTALL" "Generating uid failed!"
			return 1 
		fi
		
		RETURN[0]=${user_uid}
		return 0
	fi
}

################################################################################
# name    : tell_the_other_uid
# describe: tell the other machine this one generated uid by a file which name is certain
# input   : 
#           user_name                     user name.
#           local_uid                     generated uid.
#           float_ip                      the dual host 's float_ip
#           opposite_ip                   the other machine actual ip.
#           idx                           idx is current float_ip in the list of float_ip 's position    
# output  : 
# rerurn  : 
#           0                             success
#           1                             failed
# invoker : 
#          create_dual_user
################################################################################
function tell_the_other_uid
{
	typeset user_name=${1}
	typeset local_uid=${2}
	typeset float_ip=${3}
	typeset opposite_ip=${4}
	typeset idx=${5}
	typeset taskid=${TASK_NUM}
	
	typeset tell_file="/tmp/tmp_uid_${user_name}_${float_ip}_${idx}_${taskid}"
	typeset opposite_file="/tmp/uid_from_opposite_${user_name}_${float_ip}_${idx}_${taskid}"
	
	echo "${user_name}=${local_uid}" > "${tell_file}"
	scp "${tell_file}" "${opposite_ip}:${opposite_file}" 1>/dev/null 2>&1
	if [ $? -ne 0 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "Telling the other machine generated uid failed!"
		return 1 
	fi

	return 0
}

################################################################################
# name    : read_uid_from_opposite
# describe: read the uid form a file which name is certain
# input   : 
#           user_name                     user name.
#           float_ip                      the dual host 's float_ip
#           idx                           idx is current float_ip in the list of float_ip 's position    
# output  : 
#           the uid which generated by the other machine.
# rerurn  : 
#           0                             success
#           1                             failed
# invoker : 
#          create_dual_user
################################################################################
function read_uid_from_opposite
{
	typeset user_name="${1}"
	typeset float_ip="${2}"
	typeset idx="${3}"
	typeset taskid=${TASK_NUM}
	
	typeset uid_file="/tmp/uid_from_opposite_${user_name}_${float_ip}_${idx}_${taskid}"
	
	if [ ! -f "${uid_file}" ]
	then
		return 1 
	fi
	
	typeset read_uid=`awk -F= -v uname=$user_name '
			{
				if ($1 == uname)
				{
					print $2
					exit(0)
				}
			}' "${uid_file}"`
	if [ "-${read_uid}" = "-" ]
	then 
		return 1 
	else
		RETURN[0]=${read_uid}
	fi

	return 0
}

################################################################################
# name    : create_single_user
# describe: create a single machine's application run user.
# input   : 
#           user_name                     user name.
#           user_password                 user password
#           idx                           idx is current ne in the machine's position   
#           gid                           gid
#           user_home                     user home
#           float_ip                      the dual host 's float_ip
# output  : 
# rerurn  : 
#           0                             success
#           1                             failed
# invoker : 
#          create_dual_user
################################################################################
function create_single_user
{
	typeset user_name="${1}"
	typeset user_password="${2}"
	typeset gid="${3}"
	typeset idx="${4}"
	typeset user_home="${5}"
	typeset user_shell_1="/bin/csh"
	typeset user_shell_2="/usr/bin/csh"
	typeset is_user_created=`awk -F: -v uname=${user_name} -v ugid=${gid} -v uhome=${user_home} -v shell1=$user_shell_1 -v shell2=$user_shell_2 '
			{
				if ($1 == uname)
				{
					if($6 == uhome && $4 == ugid && ($7 == shell1 || $7 == shell2))
					{
						print 0 
					}
					else
					{
						print 1
					}
					exit(0)
				}
			}' "/etc/passwd"`
	
	typeset rt="${is_user_created}"
	if [ "-$rt" = "-1" ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "User ${user_name} existed, but not suite for the install!"
        return 1
	elif [ "-$rt" = "-0" ]
	then 
		install_log "INFO" "DSDP_INSTALL" "Creating user ${user_name} succeed!"
		return 0
	fi
	
	generating_uid "" "${idx}"
	if [ $? -ne 0 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "generating local uid failed!"
		return 1
	fi
	
	typeset local_uid=${RETURN[0]}
	
	convert_gid_to_groupname "${gid}"
	if [ $? -ne 0 ]
	then 
		return 1
	fi
	typeset group_name=${RETURN[0]}
	user_create_user "${user_name}" "${user_home}" "/usr/bin/csh" "${group_name}" "${local_uid}"
	if [ $? -ne 0 ]
	then
		install_log "ERROR" "DSDP_INSTALL" "Creating user ${user_name} failed, Maybe the user exists or the user id(${local_uid}) exists."
		return 1 
	fi
	
	user_change_passwd "${user_name}" "${user_password}"
	if [ $? -ne 0 ]
	then
		install_log "ERROR" "DSDP_INSTALL" "Changing user ${user_name} password failed!"
		return 1 
	fi
	
	install_log "INFO" "DSDP_INSTALL" "Creating user ${user_name} succeed"
	return 0
}

################################################################################
# name    : convert_gid_to_groupname
# describe: Give a gid, and return the gid's group name.
# input   :  
#           gid                           gid
# output  : 
#           group name.
# rerurn  : 
#           0                             success
#           1                             failed
# invoker : 
#          create_dual_user
#          create_single_user
################################################################################
function convert_gid_to_groupname
{
	if [ $# != 1 ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "Parameters number error, the function of convert_gid_to_groupname requires only one parameter!"
		return 1
	fi
	
	typeset group_id="${1}"
	
	typeset group_name=`awk -F: -vgid="${group_id}" '
			{
				if ($3 == gid)
				{
					print $1
					exit(0)
				}
			}' "/etc/group"`
	
	if [ "-${group_name}" = "-" ]
	then 
		install_log "ERROR" "DSDP_INSTALL" "The gid of $group_id does not exist!"
		return 1 
	fi
	
	RETURN[0]="${group_name}"
	return 0
}



