#!/usr/bin/ksh
#set -x
##################################################################################
#   Name:           build_trust_relation.sh
#   Description:    建立信任关系，需要传入对端机器的用户的密码
##################################################################################
program=`basename $0`
program_dir=`dirname $0`
if [ `echo "$0" |grep -c "/" ` -gt 0 ];then
    cd ${0%/*}
fi

. ./include.inc
. ./ideploy.inc
. ./err.inc
. ./logutil.lib

##################################################################################
#   Name:           build_trust_relation_main
#   Description:    build trust
#	input:
#       1. pwd
#   Return:    
#		0 success
#       1 failed
##################################################################################
function build_trust_relation_main
{
    typeset func_name="build_trust_relation_main"  
    typeset password=$@
    typeset user_name=""
    typeset host_ip=""
    typeset host_type=""
    typeset build_trust_relation_exp="${IDEPLOY_PKG_PATH}/script/build_trust_relation.exp"
 
    install_log "INFO" "CHECK_ENV" "Begin read ${BUILD_TRUST_RELATION_HOSTIP_KEY} from config file." 
    read_value "${BUILD_TRUST_RELATION_HOSTIP_KEY}"
    if [ $? -ne 0 ];then
        install_log "ERROR" "CHECK_ENV" "read ${BUILD_TRUST_RELATION_HOSTIP_KEY} value failed."
        return 1
    fi
    host_ip="${RETURN[0]}"
    
    if [ ! -f "${build_trust_relation_exp}" ];then
        install_log "ERROR" "CHECK_ENV" "The srcipt ${build_trust_relation_exp} not exist or not a file."
        return 1
    fi
    
    if [ -z "${password}" ];then
        install_log "ERROR" "CHECK_ENV" "The build trust relation host user password is empty."
        return 1
    fi
    
    install_log "INFO" "CHECK_ENV" "Begin build trust relation,please wait..." 
    ${build_trust_relation_exp}  root@"${host_ip}" "${password}" > /dev/null 2>&1
	if [ $? -ne 0 ];then
		install_log "ERROR" "CHECK_ENV" "Build trust relation failed by command \"${build_trust_relation_exp}  root@${host_ip} ${password} \"."
		return 1
    fi
}


    


