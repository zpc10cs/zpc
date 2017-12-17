#!/usr/bin/ksh
if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi
. ./pub.inc
. ./commfun.lib

##########################################################
#      获取up_small.ini里面配置的容器名称                #
##########################################################
function get_container_name
{
	typeset ne_rela_config="${IDEPLOY_PKG_PATH}/script/up_small.ini"
	cfg_get_sec_key_value "${ne_rela_config}" "Component_Container_Relation" "DSDPDEMO"
    if [ $? -ne 0 ]
    then 
		install_log ERROR LIB "Getting the key DSDPDEMO in segment Component_Container_Relation of ${ne_rela_config} failed."
		return 1 
	fi
	container_name="${RETURN[0]}"
}


######################################################################
#      删除module.xml里面的配置，暂不考虑有注释里面有匹配的情况      #
######################################################################

function main
{
    ${HOME}/uniAgent/bin/stop.sh
	rm -rf  ${HOME}/uniAgent/work/dsdpdemo
	${HOME}/${container_name}/bin/stop_csc.sh
	
	sleep 5
	
	echo "INFO" "=================================================="
	echo "INFO" "begin to rollback app."
	typeset file_name=${HOME}/${container_name}/conf/module.xml	
	if [ ! -f ${file_name} ];then		
		install_log "ERROR" "DSDPDEMO" "file ${file_name} doesn't exsit."
		return 1
	fi
	
	
	start_flag="0"
	start_number=0		
	end_number=0
	
	i=1
	while read line
	do		
		if [ "x${line}" == "x<module name=\"dsdpdemo\">" ];then			
			start_number=$i
			start_flag="1"
		fi
		
		if [ "x${line}" == "x</module>" -a "x${start_flag}" == "x1" ];then
			end_number=$i
			break
		fi
		((i=i+1))
	done < ${file_name}
		
	sed -i "${start_number},${end_number} d " ${file_name}
	
	rm -rf ${HOME}/${container_name}/modules/dsdpdemo
	
	echo "INFO" "rollback app success."
	return 0


}

typeset component=dsdpdemo
typeset container_name

get_container_name

main
if [ $? -ne 0 ]; then
	install_log "ERROR" "${component}" "invoke function:: main()  failed."
	return 1
fi
