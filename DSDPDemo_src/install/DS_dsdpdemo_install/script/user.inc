#!/bin/ksh

################################################################################
# name       : user.inc
# describe   : create group and user and change passwd
# ModuleName : Install
# Copyright  : Huawei Technologies Co., Ltd. 
# date       : 2006-07-07
# functions  : user_create_group          : create group
#              user_create_user           : create user
#              user_change_passwd         : change password
#              user_is_exist              : judge whether the user exists
#              user_is_group_exist        : judge whether the group exists
#              user_is_user_have_password : judge whether the user has password
#              user_get_user_group        : get the user's group 
#################################################################################

################################################################################
# name    : create_group
# describe: create group
# input   : group_name 
#            group_id
# output  : null
# rerurn  : $SUCC                          success
#           $ERR_USER_USE_EXIST_GROUP      user the existent group
#           $PARA_ERROR                    parameter error
#           $ERR_USER_GROUP_EXIST          the group exists
#           $ERR_USER_GROUP_ID_EXIST       the group id exists 
#           $ERROR                         failed to ceate group
# invoker : user.inc
################################################################################
function user_create_group  # for SUN HP Linux IBM
{
    typeset func_name="create_group"
    
    typeset group_name="$1"
    typeset group_id="$2"
    
    if [ $# -ne 2 -a $# -ne 1 -o -z "$1" ]; then
    	return $PARA_ERROR
    fi   
    
    user_is_group_exist $group_name
    rt=$?
    if [ $rt -ne 0 ]; then            #the group do not exist in the system
    	#if [ -n "$group_id" -a `awk -F: '{print $3}' /etc/group | grep -c "^${group_id}$"` -ne 0 ]; then
    	#    return $ERR_USER_GROUP_ID_EXIST
    	#fi     
    	#user_add_group  $group_name $group_id
    	#if [ $? -eq 0 ]; then
    	#    return $SUCC
    	#else
    	#    return $ERROR
    	#fi
		ostype=$(uname -s)
		if [ "x${ostype}" = "xAIX" ]; then
			:
		else
			if [ -n "${group_id}" ]; then
				groupadd -g ${group_id} ${group_name} > /dev/null 2>&1
				rt=$?
				if [ ${rt} -eq 0 ]; then
					return ${SUCC}
				elif [ ${rt} -eq 9 ]; then
					typeset gname=$(awk -F: -vgid=${group_id} '{ if(gid == $3) { print $1;exit 0 } }' /etc/group)
					if [ -n "${gname}" -a "x${gname}" = "x${group_name}" ]; then
						return ${ERR_USER_USE_EXIST_GROUP}
					else
						return ${ERR_USER_GROUP_EXIST}
					fi
				elif [ ${rt} -eq 16 ]; then
					typeset gname=$(awk -F: -vgid=${group_id} '{ if(gid == $3) { print $1;exit 0 } }' /etc/group)
					if [ -n "${gname}" -a "x${gname}" = "x${group_name}" ]; then
						return ${ERR_USER_USE_EXIST_GROUP}
					else
						return ${ERR_USER_GROUP_ID_EXIST}
					fi
				else
					return ${ERROR}
				fi
			else
				groupadd ${group_name}
				rt=$?
				if [ ${rt} -eq 0 ]; then
					return ${SUCC}
				# group exists
				elif [ ${rt} -eq 9 ]; then
					return ${ERR_USER_USE_EXIST_GROUP}
				else
					return ${ERROR}
				fi
			fi
		fi
    elif [ -n "$group_id" ]; then
    	user_get_group_id $group_name
    	if [ -n "${RETURN[0]}" -a ${RETURN[0]} -ne $group_id ]; then
    	    return $ERR_USER_GROUP_EXIST
    	fi
    	return $ERR_USER_USE_EXIST_GROUP
    else
    	return $ERR_USER_USE_EXIST_GROUP
    fi
}    

################################################################################
# name    : user_create_user
# describe: create user 
# input   : user_name
#           user_home
#           user_shell
#           user_group
#           user_id ( null is allowed )
#           user_accessorial_group ( null is allowed )
# output  : null
# rerurn  : $SUCC                              success
#           $PARA_ERROR	                       parameter error 
#           $ERR_USER_GROUP_NOT_EXIST          the group do not exist
#           $ERR_USER_USER_EXIST               the user exists
#           $ERR_USER_USER_ID_EXIST            the user id exists
#           $ERR_USER_SHELL_NOT_EXIST          the shell type do not exist
#           $ERROR                             failed to ceate group
# invoker : user.inc
################################################################################
function user_create_user  # For SUN HP Linux  IBM
{       
    typeset func_name="user_create_user"
    typeset tmp_file="tmp_file"
    typeset user_name="$1"
    typeset user_home="$2"
    typeset user_shell="$3"
    typeset user_group="$4"
    typeset user_id="$5"
    typeset user_groups="$6"
    typeset params=""
    if [ -z "$user_name" ]; then
    	return $PARA_ERROR
    fi
    
    ##the group do not exist
    if [ -n "$user_group" ]; then
    	user_is_group_exist $user_group
    	if [ $? -ne 0 ]; then 
    	    return $ERR_USER_GROUP_NOT_EXIST #组不存在
    	fi
    fi
    
    
    ##check shell
    if [ -n "$user_shell" -a ! -f "$user_shell" ]; then
    	return $ERR_USER_SHELL_NOT_EXIST
    fi
    
    
    ##check accessorial group 
    if [ -n "$user_groups" ]; then
    	for params in `echo $user_groups | sed 's/,/ /g'`
    	do
    	    user_is_group_exist $params
    	    if [ $? -ne 0 ]; then
    	    	return $ERROR
    	    fi
    	done
    fi

    typeset ret=0
    user_is_exist "$user_name"
    if [ $? -ne 0 ]; then     ##the user do not exist
    	if [ -n "$user_id" -a `awk -F: '{print $3}' /etc/passwd | grep -c "^$user_id$"` -ne 0 ]; then
    		return $ERR_USER_USER_ID_EXIST
    	fi
    
    	params=" $user_name"
    	if [ -n "${user_home}" ]; then
    	    if [ ! -d "$user_home" ]; then
    	    	mkdir -p "`dirname $user_home`"
    	    	if [ $? -ne 0 ]; then
    	    		return $ERROR
    	    	fi
    	    	params="-m $params"
    	    fi
    	    params="-d ${user_home} $params"
    	fi
    	if [ -n "${user_id}" ]; then
    	    params="-u ${user_id} $params"
    	fi
    	if [ -n "${user_shell}" ]; then
    	    params="-s ${user_shell} $params"
    	fi
    	if [ -n "${user_group}" ]; then
    	    params="-g ${user_group} $params"
    	fi
    	
    	useradd $params 1> /dev/null 2>/tmp/usererr_$$.tmp
    	if [ $? -ne 0 ]; then
    	    return $ERROR
    	fi
    	ret=$SUCC
    else    ##the user has existed
    	##check whether the group are same
    	if [ -n "$user_group" ]; then
    	    user_get_user_group "$user_name"
    	    params="`echo ${RETURN[0]}`"
    	    if [ "$user_group" != "$params" ]; then
    	    	return $ERR_USER_USER_EXIST
    	    fi
    	fi 
    	
    	##check whether the home path are same 
    	if [ -n "$user_home" ]; then
    	    user_get_user_home "$user_name"
    	    if [ "$user_home" != "${RETURN[0]}" ]; then
    	    	return $ERR_USER_USER_EXIST
    	    fi
    		
    	fi
    	
    	##check whether the shell are same 
    	if [ -n "$user_shell" ]; then
    	    user_get_user_shell "$user_name"
    	    params="`echo ${RETURN[0]}`"
    	    if [ "$user_shell" != "$params" ]; then
    	    	return $ERR_USER_USER_EXIST
    	    fi
    	fi
    	
    	##check whether the user id are same
    	if [ -n "$user_id" ]; then
    	    user_get_user_id "$user_name"
    	    params="`echo ${RETURN[0]}`"
    	    if [ "$user_id" != "$params" ]; then
    	    	return $ERR_USER_USER_EXIST
    	    fi
    	fi
    	ret=$ERR_USER_USE_EXIST_USER
    fi
    
    ##join in other group
    if [ -n "$user_groups" ]; then
    	usermod -G ${user_groups} "$user_name" 2> /dev/null
    fi
    
    ##set the owner of the home path
    user_get_user_group "$user_name"
    user_group="`echo ${RETURN[0]}`"
    user_get_user_home "$user_name"
    user_home="`echo ${RETURN[0]}`"
    mkdir -p $user_home
	
	typeset actual_user_shell=""
    if [ -n "$user_shell" ]; then
		actual_user_shell="$user_shell"
	else
		user_get_user_shell "$user_name"
    	params="${RETURN[0]}"
		actual_user_shell=$params
	fi
	
	if [ "X$actual_user_shell" == "X/bin/csh" -o "X$actual_user_shell" == "X/bin/tcsh" -o "X$actual_user_shell" == "X/usr/bin/csh" -o "X$actual_user_shell" == "X/usr/bin/tcsh" ]
	then
		echo "setenv LANG en_US.UTF8" >> "${user_home}/.cshrc"
	elif [ "X$actual_user_shell" == "X/bin/sh" -o "X$actual_user_shell" == "X/usr/bin/sh" -o "X$actual_user_shell" == "X/bin/bash" -o "X$actual_user_shell" == "X/bin/ksh" -o "X$actual_user_shell" == "X/usr/bin/ksh" -o "X$actual_user_shell" == "X/usr/bin/bash" ]
	then
		echo "export LANG=en_US.UTF8" >> "${user_home}/.profile"
	fi
		
    chown -R ${user_name}:${user_group} ${user_home}
           
    return $ret
}


################################################################################
# name    : user_change_passwd
# describe: change password 
# input   : user_name
#           user_password
# output  : null
# rerurn  : $SUCC                              success           
#           $PARA_ERROR                        parameter error 
#           $ERROR                             failed to change password
# invoker : user.inc
################################################################################
function user_change_passwd # for SUN HP IBM Linux
{
    if [ $# -ne 2 -o -z "$1" -o -z "$2" ]; then
    	return $PARA_ERROR
    fi
    typeset user_name="$1"
    typeset user_passwd="$2"
    typeset rhostfile="/.rhosts"
    typeset hostname=`hostname`
    typeset -i time_wait1=2
    typeset -i time_wait2=1
           
    if [ ! -f $rhostfile ]; then
    	touch $rhostfile
    fi
    if [ `grep -c "$hostname root" $rhostfile` -eq 0 ]; then
    	echo "$hostname root" >> $rhostfile
    fi
    
    user_is_exist $user_name
    if [ $? -ne 0 ]; then
    	return $ERR_USER_USER_NOT_EXIST
    fi
    
    uname=`uname`
    if [ "X$uname" = "XLinux" ] ; then
		while true
		do	
			{
				sleep $time_wait1
				echo "$user_passwd"
				sleep $time_wait2
				echo "$user_passwd"
				sleep $time_wait2
			} | passwd $user_name 1> /dev/null 2> /dev/null

			user_is_user_have_password $1
			if [ $? -eq 0 ]; then # 密码已经存在
				break     
			fi
			
			((time_wait1+=2))
			((time_wait2+=1))
			if [ time_wait1 -gt EXPIRE_TIME ]; then #超时退出
				return $ERROR
			fi
        done  
    else
    
        read_ideploy_value  "_hostip"
        ip_addr=${RETURN[0]}    

        {
        	sleep $time_wait1
        	echo "passwd $user_name"
        	sleep $time_wait1	
        	echo "$user_passwd"
        	sleep $time_wait2   
        	echo "$user_passwd"
        	echo 
        	sleep $time_wait2
        } | rlogin $ip_addr 1>/dev/null 2>&1
        
        uname=`uname`
        if [ "x${uname}" = "xAIX" ]; then
            {
                 sleep $time_wait1
                 echo "$user_passwd"
                 sleep $time_wait1
                 echo "$user_passwd"
                 sleep $time_wait2 
                 echo "$user_passwd"
                 echo
                 sleep $time_wait2
            } | rlogin $ip_addr  -ex -l $user_name 1>/dev/null 2>&1
        fi
    fi 
    return $SUCC
}

################################################################################
# name    : user_is_exist
# describe: judge where the user exist 
# input   : user_name
#            user_password
# output  : null
# rerurn  : $YES                          the user exists
#           $PARA_ERROR                   parameter error 
#           $NO				  the user do not exist
# invoker : user.inc
################################################################################
function user_is_exist # for SUN HP IBM Linux
{
    if [ $# -ne 1 ]; then
    	return $PARA_ERROR
    fi
    typeset user_name=$1
        
    id $user_name 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
    	return $NO
    fi	
    return $YES
}

################################################################################
# name    : user_is_group_exist
# describe: judge where the group exist 
# input   : group_name
# output  : null
# rerurn  : $YES                       the user exists
#           $PARA_ERROR                   parameter error 
#           $NO				  the user do not exist
# invoker : user.inc
################################################################################
function user_is_group_exist # for SUN HP LINUX IBM
{
    if [ $# -ne 1 ]; then
    	return $PARA_ERROR
    fi	
    typeset group_name="$1"
    
    ostype=`uname -s`
    if [ "X$ostype" = "XAIX" ]; then            #IBM
        ngroup=`lsgroup ALL | awk '{ print $1}' |grep "^$group_name$" | wc -l`
        if [ $ngroup -eq 0 ]; then
        	return $NO                          #the group do not exist
        else
        	return $YES                         #the group exists
        fi
    else                                        #other type of machine
		groupmod $group_name 2>/dev/null
		if [ $? -eq 0 ]; then
			return $YES                         ##the group exists
		else
			return $NO                          #the group do not exist
		fi
	fi
}

################################################################################
# name    : user_is_user_have_password
# describe: judge where the password has been set 
# input   : user_name
# output  : null
# rerurn  : $YES                          the password has been set
#           $PARA_ERROR                   parameter error 
#           $NO				  the password has not been set
# invoker : user.inc
################################################################################
function user_is_user_have_password  #for SUN HP except IBM Linux
{
    if [ $# -ne 1 ]; then
    	return $PARA_ERROR
    fi
        
    typeset user_name="$1"
    
    uname=`uname`
    if [ "X$uname" = "XLinux" ] ; then
        have_passwd=`passwd -S $user_name | awk '{print $2}'`
        if [ "-$have_passwd" = "-PS" ]; then
            return $YES
        else
            return $NO	  		
        fi
    else   
        have_passwd=`passwd -s $user_name | awk '{print $2}'`
        have_passwd=`echo $have_passwd` 
        if [ "-$have_passwd" = "-PS" ]; then
			return $YES
        else
         	return $NO	  		
        fi
    fi
}


################################################################################
# name    : user_add_group
# describe: create group
# input   : group_name
#           [group_id]
# output  : null
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to create group
# invoker : user.inc
################################################################################
function user_add_group # for SUN HP Linux  IBM
{
    typeset group_name="$1"
    typeset group_id="$2"
    
    if [ $# -ne 1 -a $# -ne 2 ]; then
    	return $PARA_ERROR	
    fi
    
    ostype=`uname -s`  
    if [ $# -eq 2 ]; then	    
        if [ "X$ostype" = "XAIX" ] ; then 
    	    mkgroup -A id=$group_id $group_name  >/dev/null 2>/tmp/grouperr_$$.tmp
    	    if [ $? -ne 0 ]; then
				return $ERROR          #fail
    	    else
				return $SUCC           #success
    	    fi 
        else  
            groupadd -g $group_id $group_name    >/dev/null 2>/tmp/grouperr_$$.tmp    
    	    if [ $? -ne 0 ]; then
				return $ERROR          #fail
    	    else
				return $SUCC           #success
    	    fi
        fi		
    else	
        if [ "X$ostype" = "XAIX" ] ; then	
    	    mkgroup $group_name    >/dev/null 2>/tmp/grouperr_$$.tmp
    	    if [ $? -ne 0 ]; then
    	        return $ERROR         #fail
    	    else
    	        return $SUCC          #success
    	    fi	
        else
            groupadd $group_name   >/dev/null 2>/tmp/grouperr_$$.tmp
    	    if [ $? -ne 0 ]; then
				return $ERROR         #fail
    	    else
				return $SUCC          #success
    	    fi
        fi
    fi    
}


################################################################################
# name    : user_get_group_id
# describe: get the id of appointed group
# input   : user_name
# output  : RETURN[0]=group_id
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to get the id of appointed group
# invoker : user.inc
################################################################################
function user_get_group_id
{
    if [ $# -ne 1 -o -z "$1" ]; then
    	return $PARA_ERROR
    fi
    typeset group_name=$1
    typeset group_id=`grep "^${group_name}:" /etc/group |awk -F: '{print $3;exit 0}'`
    if [ $? -ne 0 ]; then
    	return $ERROR
    fi
    
    RETURN[0]=`echo ${group_id}`
    RETNUM=1
    
	return $SUCC
}

################################################################################
# name    : user_get_user_group
# describe: get the name of appointed group
# input   : user_name
# output  : RETURN[0]=group_name
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to get the name of appointed group
# invoker : user.inc
################################################################################
function user_get_user_group
{  
    if [ $# -ne 1 ]; then
		return $PARA_ERROR
    fi
    
    typeset func_name="user_get_user_group"    
    
    typeset user_name=$1   
    #get the name of appointed group
    typeset group_name=`id "$user_name" |awk -F\( '{print $3}' | awk '{slen=length($1);print substr($1,1,slen-1);}' 2>/dev/null `

    #return the name of group
    RETURN[0]=`echo ${group_name}`
    RETNUM=1
    
    return $SUCC
}

################################################################################
# name    : user_get_user_home
# describe: get the home of appointed user
# input   : user_name
# output  : RETURN[0]=group_home
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to get the home of appointed user
# invoker : user.inc
################################################################################
function user_get_user_home
{
    if [ $# -ne 1 ]; then
		return $PARA_ERROR
    fi

    typeset func_name="user_get_user_home"    
    typeset user_name=$1   
	
    typeset user_home=`cat /etc/passwd | grep ^${user_name}: | awk -F: '{print $6}' 2>/dev/null`

    RETURN[0]=`echo ${user_home}`
    RETNUM=1

    if [ -z "${RETURN[0]}" ]; then
		return $ERROR
    fi
    return $SUCC
}

################################################################################
# name    : user_get_user_id
# describe: get the id of appointed user
# input   : user_name
# output  : RETURN[0]=user_id
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to get the id of appointed user
# invoker : user.inc
################################################################################
function user_get_user_id
{
    if [ $# -ne 1 ]; then
		return $PARA_ERROR
    fi

    typeset func_name="user_get_user_group"    
    typeset user_name=$1   
	
    typeset user_id=`cat /etc/passwd | grep ^${user_name}: | awk -F: '{print $3}' 2>/dev/null`

    RETURN[0]=`echo ${user_id}`
    RETNUM=1

    if [ -z "${RETURN[0]}" ]; then
		return $ERROR
    fi
    return $SUCC
}

################################################################################
# name    : user_get_user_shell
# describe: get the shell of appointed user
# input   : user_name
# output  : RETURN[0]=user_shell
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to get the shell of appointed user
# invoker : user.inc
################################################################################
function user_get_user_shell
{
    if [ $# -ne 1 ]; then
        return $PARA_ERROR
    fi
                
    typeset func_name="user_get_user_group"    
    typeset user_name=$1   
	
    typeset user_shell=`cat /etc/passwd | grep ^${user_name}: | awk -F: '{print $7}' 2>/dev/null`

    RETURN[0]=`echo ${user_shell}`
    RETNUM=1
	
    if [ -z "${RETURN[0]}" ]; then
		return $ERROR
    fi
	return $SUCC
}

################################################################################
# name    : user_delete_user
# describe: delete the user
# input   : whether delete the home of the user             
#           user_name
# output  : null
# rerurn  : $SUCC                           success
#           $PARA_ERROR                     parameter error 
#           $ERROR                          failed to delete the user
# invoker : user.inc
################################################################################
function user_delete_user
{
    typeset func_name="delete_user"
	
    typeset delete_r="$1"
    typeset delete_name="$2"
    typeset rt=""
    
    if [ $# -ne 2 ]; then
    	return $PARA_ERROR
    fi
    
    if [ -z "$delete_name" ]; then
    	return $PARA_ERROR
    fi
    
    userdel $delete_r $delete_name 
    
    rt=$?
    
    if [ $rt = 0 ]; then
		return $SUCC
    else 
		return $rt
    fi
}


