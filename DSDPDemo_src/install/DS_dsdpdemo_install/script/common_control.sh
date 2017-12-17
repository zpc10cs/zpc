#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

################################################################################
# name       : common_control.sh
# describe   : install common control script,
# ModuleName : common control
# Copyright  : Huawei Technologies Co., Ltd. 
# date       : 2008-11-24
# functions  : install    : install  
#  
################################################################################
. ./commonlib.inc

################################################################################
# name    : invoke_middle_script
# describe: install control script,invoke dsdp_install.sh,DSDP_REFRESH.sh,
#           dsdp_uninstall.sh,dsdp_init.sh,dsdp_start.sh,dsdp_stop.sh,
#           dsdp_status_check.sh,
#           mdsp_test.sh
# param1  : install,refresh,init,start,stop,status,uninstall,test
# rerurn  : 0:success
#           1:faild
################################################################################
function invoke_middle_script
{ 
    typeset param="$1"
	typeset basic_install_const="basic_install"
    typeset install_const="install"
    typeset refresh_const="refresh"
    typeset init_const="init"
    typeset start_const="start"
    typeset stop_const="stop"
    typeset status_const="status"
    typeset uninstall_const="uninstall"
    typeset test_const="test"
    
    case $param in
		$basic_install_const)
			./basic_install.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_install.sh"
                return 1
            fi
            ;;
        $install_const)
            ./dsdp_install.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_install.sh"
                return 1
            fi
            ;;
        $refresh_const)
            ./dsdp_refreshcfg.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke DSDP_REFRESH.sh"
                return 1
            fi
            ;;
      
        $init_const)
            ./dsdp_init.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_init.sh"
                return 1
            fi
            ;;
        
        $start_const)
            ./dsdp_start.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_start.sh"
                return 1
            fi
            ;;
        
        $stop_const)
            ./dsdp_stop.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_stop.sh"
                return 1
            fi
            ;;
        
        $status_const)
            ./dsdp_status_check.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_status_check.sh"
                return 1
            fi
            ;;

        $uninstall_const)
            ./dsdp_uninstall.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_uninstall.sh"
                return 1
            fi
            ;;

        $test_const)
            ./dsdp_conn_check.sh
            if [ $? -ne 0 ]; then
                install_log "ERROR" "common_control" "Failed to invoke dsdp_conn_check.sh"
                return 1
            fi
            ;;
            
            *)
                install_log "ERROR" "common_control" "invalid param :" $param
                return 1
            ;; 
    esac   
    
    return 0
}

#if the number of params is more than 1 or equals 0, return 1  
if [[ $# > 1 ]] || [[  $# = 0 ]]; then
    install_log "ERROR" "common_control" "the number of param is " $# ". This script just supports 1 param. param is: " $*
    return 1
fi

#invoke middle script ,such as DSDP_INSTALL,DSDP_REFRESH,mdsp_init and so on
invoke_middle_script $@ 
if [ $? -ne 0 ]; then
	return 1
else
	return 0
fi

 


