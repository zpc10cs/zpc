#!/usr/bin/ksh
if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi
. ./pub.inc
#########################################
#      read_base_info			        #
#########################################
function read_base_info
{
    ###########################################
	 #          Get Server Ip and Port
	###########################################
	install_log "INFO" "DEMO" "start read base info."
	get_localhost_ip
	if [ $? -ne 0 ]; then
		install_log "ERROR" "DEMO" "getting local host ip failed."
		return 1
	fi
	demo_local_ip=${RETURN[0]}
	read_value "dsdpdemo_service_port"
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "read_value dsdpdemo_service_port failed."
		return 1
	fi
	dsdpdemo_service_port="${RETURN[0]}"
	((demo_local_ip_offset_monitor_port=dsdpdemo_service_port+2))
	((demo_local_ip_offset_logserver_port=dsdpdemo_service_port+2))
	((jmx_port=dsdpdemo_service_port+1))
	((demo_usf_server_port=dsdpdemo_service_port+5))
    dsdpdemo_port=${demo_local_ip}:${demo_local_ip_offset_logserver_port}
	typeset Pid_Name="lsof -n -i:${dsdpdemo_service_port} | grep java | grep LISTEN | awk '{printf \"%s %s\",\$2,\$3}'"
    sed -i 's#admintooladrr=.*#admintooladrr='"${dsdpdemo_port}"'#g' ${HOME}/ideploy/dsdpdemo/script/dsdpdemo_comp.cfg
    sed -i 's#CheckPort=.*#CheckPort='"${demo_local_ip_offset_monitor_port}"'#g' ${HOME}/ideploy/dsdpdemo/script/monitor/monitor.cfg
	sed -i 's#CheckIp=.*#CheckIp='"${demo_local_ip}"'#g' ${HOME}/ideploy/dsdpdemo/script/monitor/monitor.cfg
	sed -i 's#PidName=.*#PidName='"${Pid_Name}"'#g' ${HOME}/ideploy/dsdpdemo/script/monitor/monitor.cfg
	
    typeset demo_home=`echo $HOME`
	sed -i 's#demo_enterprise#'"${demo_home}"'#g' ${HOME}/ideploy/dsdpdemo/script/dsdpdemo_comp.cfg

	###########################################
	 #         Get zookeeper IP and Port 
	###########################################
	#zookeeper
	read_value "zookeeper_service_dsf_port"
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "read value zookeeper_service_dsf_port failed."
		return 1
	fi
	zk_port="${RETURN[0]}"
	
	read_value "zookeeper_service_dsf_ip"
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "read_value zookeeper_service_dsf_ip failed."
		return 1
	fi
	zk_ips="${RETURN[0]}"
	zk_ip_array=`echo ${zk_ips} | sed "s#,# #g"`
	typeset zk_ip_port=""
	for ip in ${zk_ip_array}
	do
        	zk_ip_port="${zk_ip_port}${ip}:${zk_port},"
	
	done
	zk_ip=`echo $zk_ip_port|cut -c1-$((${#zk_ip_port}-1))`
	
	#zookeeper_config
	read_value "zookeeper_service_config_ip"
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DSDPDEMO" "read_value zookeeper_service_config_ip failed."
		return 1
	fi
	zk_ips_config="${RETURN[0]}"
	read_value "zookeeper_service_config_port"
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DSDPDEMO" "read value zookeeper_service_config_port failed."
		return 1
	fi
	zk_port_config="${RETURN[0]}"
	
    zk_ip_array_config=`echo ${zk_ips_config} | sed "s#,# #g"`
	typeset zk_ip_port_config=""
	for ips in ${zk_ip_array_config}
	do
        	zk_ip_port_config="${zk_ip_port_config}${ips}:${zk_port_config},"
	
	done
	zk_ip_config=`echo $zk_ip_port_config|cut -c1-$((${#zk_ip_port_config}-1))`
	
    
	###########################################
	#            Get Redis Ip and Port
	###########################################
	#redis
    read_value "dsdpdemo_redis_service_url.size"
    if [ $? -ne 0 ];then
	install_log "ERROR" "DEMO" "Get redis_ip failed"
	return 1
    fi
    redis_service_url_size=${RETURN[0]}


    typeset -i idx=0
    redis_url=""
	redisaddr=""
    while [ ${idx} -lt ${redis_service_url_size} ]
    do
		read_value "dsdpdemo_redis_service_url.${idx}"
		if [ $? -ne 0 ];then
			install_log "ERROR" "DEMO" "Get redis_url failed"
			return 1
		fi
		redis_service_url=${RETURN[0]}

		redis_ip=$(echo ${redis_service_url} | awk -F: '{print $1}')
		redis_port=$(echo ${redis_service_url} | awk -F: '{print $2}')
		redis_url="${redis_url}${redis_ip}:${redis_port}|"
		redisaddr="${redisaddr}${redis_ip}:${redis_port},"
		((idx=idx+1))
	done
    redis_url=`echo ${redis_url} | sed 's/.$//'`
	redisaddr=`echo ${redisaddr} | sed 's/.$//'`
    sed -i 's#redisaddr=.*#redisaddr='"${redisaddr}"'#g' ${HOME}/ideploy/dsdpdemo/script/dsdpdemo_comp.cfg
	
	###########################################
	#    Get Oracle Information
	###########################################
	#oracle

		read_value "oracle_server_port"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "DEMO" "read value oracle_server_port failed."
			return 1
		fi
		oracle_info_server_port="${RETURN[0]}"
		
		read_value "oracle_server_sid"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "DEMO" "read value oracle_server_sid failed."
			return 1
		fi
		oracle_info_server_sid="${RETURN[0]}"
		
		#server_type
		read_value "oracle_server_type"
		if [ $? -ne 0 ]; then
			oracle_server_type=""
		fi
		oracle_server_type=${RETURN[0]}
		#address_No-RAC
		if [ "${oracle_server_type}x" == "No-RACx"  -o "${oracle_server_type}x" == "x" ]; then		
			read_value "oracle_server_ip"
			if [ $? -ne 0 ]; then
				install_log "ERROR" "DEMO" "read value oracle_server_ip failed."
				return 1
			fi
			oracle_info_server_ip=${RETURN[0]}
			db_address_list="(ADDRESS=(PROTOCOL=TCP)(HOST=${oracle_info_server_ip})(PORT=${oracle_info_server_port}))"
		fi
		
		#address_RAC
		if [ "${oracle_server_type}x" == "RACx" ]; then		
			read_value "oracle_server_standby_ip.size"
			if [ $? -ne 0 ]; then
				install_log "ERROR" "DEMO" "read value oracle_server_standby_ip.size failed."
				return 1
			fi
			typeset oracle_info_standby_ip_size=${RETURN[0]}
			typeset -i i=0
			while [ $i -lt ${oracle_info_standby_ip_size} ]
			do
				read_value "oracle_server_standby_ip.${i}"
				if [ $? -ne 0 ]; then
					install_log "ERROR" "DEMO" "read value oracle_server_standby_ip.${i} failed."
					return 1
				fi
				oracle_info_standby_ip=${RETURN[0]}
			    db_address_list="${db_address_list}(ADDRESS=(PROTOCOL=TCP)(HOST=${oracle_info_standby_ip})(PORT=${oracle_info_server_port}))"
			((i=i+1))
			done
		fi
		
		read_value "db_user_name"
		if [ $? -ne 0 ]; then
			install_log "ERROR" "DEMO" "read value db_user_name failed."
			return 1
		fi
		oracle_DSDPDEMOdb_username="${RETURN[0]}"
		#password
        read_value "db_user_password"
        if [ $? -ne 0 ]; then
           install_log "ERROR" "DSDPDEMO" "read db_user_password failed."
           return 1
        fi

        typeset oracle_demodb_password="${RETURN[0]}"
           decodePwd "${oracle_demodb_password}"
           if [ $? -ne 0 ] ; then
           install_log "ERROR" "DSDPDEMO" "decodePwd failed."
           return 1
           fi
           oracle_user_pwd="${RETURN[0]}"
           install_log "INFO" "DSDPDEMO" "decodePwd successful!"
           install_log "INFO" "DSDPDEMO" " start encodepwd !"
           cd ${dbtools_script_home}
			chmod -R 755 ${dbtools_script_home}/*
			source $HOME/.cshrc
			
		typeset user_passwd_encode=$((echo ${oracle_user_pwd};echo)|./encryptPwd.sh 0)
		 if [ $? -ne 0 ] ; then
            install_log "ERROR" "DSDP_DEMO" "encodePwd server failed."
            return 1
         fi
		 
	    tmpServerPort=`echo "${user_passwd_encode}"|awk -F ' ' '{print $1}'`

        serverPort=${tmpServerPort##*Key:}

        serverPassword=${user_passwd_encode#*Password:}

		#modify dsf password
        user_passwd_encode=${serverPassword}
		
	    grep -qe 'bme.encryption.key' ${bme_secretkey_file_path}
    
	    #not exist ,add
	    if [ $? -ne 0 ]
        then
	    {
	       echo "bme.encryption.key=${serverPort}" >>  ${bme_secretkey_file_path}
	    }
	    else
	    {
		
		#modify the bme.secretkey.properties bme.encryption.key
		sed -i "s#^bme\.encryption\.key=.*#bme\.encryption\.key=${serverPort}#g" ${bme_secretkey_file_path}
		}
		fi
	    
        user_pwd="${user_passwd_encode}"
		
	#zk auth password
	read_value "zookeeper_auth_password"
        if [ $? -ne 0 ]; then
           install_log "ERROR" "DSDPDEMO" "read zookeeper_auth_password failed."
           return 1
        else

          typeset zk_auth_password="${RETURN[0]}"
           decodePwd "${zk_auth_password}"
           if [ $? -ne 0 ] ; then
           install_log "ERROR" "DSDPDEMO" "decodePwd zk failed."
           return 1
           fi
           zk_auth_pwd="${RETURN[0]}"
           install_log "INFO" "DSDPDEMO" "decodePwd zk successful!"
           install_log "INFO" "DSDPDEMO" " start zk encodepwd !"
           cd ${dbtools_lib_home}

        

        typeset user_inter_encode=`java -jar com.huawei.itpaas.common.security-1.1.20.jar encrypt ${zk_auth_pwd} factory ${cipher_path}`

		 if [ $? -ne 0 ] ; then
            install_log "ERROR" "DSDPDEMO" "encodePwd failed."
            return 1
         fi
           inter_pwd="${user_inter_encode}"
         cd -
         install_log "INFO" "DSDP_DEMO" "encodePwd zk successful!"
         
	    sed -i "s#paas_inter_password.*#paas_inter_password=${inter_pwd}#g" ${itpaas_path}
        fi
	read_value "zookeeper_auth_name"
	if [ $? -ne 0 ]; then
			install_log "ERROR" "DSDP_DEMO" "read value zookeeper_auth_name failed."
			return 1
	fi
	zookeeper_auth_name="${RETURN[0]}"	
	sed -i "s#paas_inter_user.*#paas_inter_user=${zookeeper_auth_name}#g" ${itpaas_path}	
	read_value "zk_auth_switch"
	if [ $? -ne 0 ]; then
			install_log "ERROR" "DSDPDEMO" "read value zk_auth_switch failed."
			return 1
		fi
		zk_auth_switch="${RETURN[0]}"
		sed -i "s#zk.auth.switch.*#zk.auth.switch=${zk_auth_switch}#g" ${dsf_file_path}
		
}

################################################
#            �޸� �����־�������� ��Ϣ        #
################################################
function modify_env
{
	install_log "INFO" "DSDPDEMO" "start modify pre_start.sh."
	typeset file_name=${container_name}/bin/pre_start.sh
	
	sed -i "$ aCUSTOM_JVM_OPT=\"-DPAAS_HOST_ID=${demo_local_ip}:${dsdpdemo_service_port} -DPAAS_CLUSTER_ID=dsdpdemo\"" ${file_name}
	if [ $? -ne 0 ];then
        install_log "ERROR" "DSDPDEMO" "sed pre_start.sh failed"
        return 1
	fi	
}

function modify_factor_info
{
	install_log "INFO" "DSDP_DEMO" "start modify factor info."


	typeset factor=${HOME}/dsdpdemo_container/bin/factor.sh
	if [ -f ${factor} ]
	then
		cd ${HOME}/dsdpdemo_container/bin
		factor_pwd=`${factor}`;
		cd - > /dev/null
	else
		install_log "ERROR" "DSDP_DEMO" "${factor} not exist."
		return 1
	fi
	
	if [  -f "${keyfactor_cbc}" ]; then
	    startLine=`sed -n '/encryption.key.factor/=' $keyfactor_cbc`
        lineAfter=1 
        let endLine="startLine + lineAfter" 
        sed -i $startLine','$endLine'd' $keyfactor_cbc
		echo "encryption.key.factor=${factor_pwd}\n" >> "${keyfactor_cbc}"
		if [ $? -ne 0 ];then
			install_log "ERROR" "DSDP_DEMO" "sed keyfactor_cbc failed"
			return 1
		fi
	fi
	
	if [  -f "${keyfactor_checksametools}" ]; then
	    startLine=`sed -n '/encryption.key.factor/=' $keyfactor_checksametools`
        lineAfter=1 
        let endLine="startLine + lineAfter" 
        sed -i $startLine','$endLine'd' $keyfactor_checksametools
		echo "encryption.key.factor=${factor_pwd}\n" >> "${keyfactor_checksametools}"
		if [ $? -ne 0 ];then
			install_log "ERROR" "DSDP_DEMO" "sed keyfactor_checksametools failed"
			return 1
		fi
	fi
	
	if [  -f "${keyfactor_conf}" ]; then
	    startLine=`sed -n '/encryption.key.factor/=' $keyfactor_conf`
        lineAfter=1 
        let endLine="startLine + lineAfter" 
        sed -i $startLine','$endLine'd' $keyfactor_conf
		echo "encryption.key.factor=${factor_pwd}\n" >> "${keyfactor_conf}"
		if [ $? -ne 0 ];then
			install_log "ERROR" "DSDP_DEMO" "sed keyfactor_conf failed"
			return 1
		fi
	fi
	
	
}


################################################
# Modify conf/dsdpdemo.localResource.properties #
################################################
function modify_localResource
{
	install_log "INFO" "DEMO" "start modify iread.jdbc.properties."

	typeset file_name=${demo_home}/conf/dsdpdemo.resource.properties
	
	typeset file_name1=${demo_home}/conf/dsdpdemo.localConfig.properties
	
	#sed -i "s/#dsdpdemodb\[1\]\.connect/dsdpdemodb\[1\]\.connect/g" ${file_name}
	sed -i "s%dsdpdemodb\[1\]\.connect=.*%dsdpdemodb\[1\]\.connect=jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=${db_address_list}(LOAD_BALANCE=no)(FAILOVER=on))(CONNECT_DATA=(SERVICE_NAME=${oracle_info_server_sid})))|${oracle_DSDPDEMOdb_username}|${user_pwd}|20|100|80|40|60000|true|true|3000|select 1 from dual|true|300000|20%g" ${file_name}
	#sed -i "s/#dsdpdemodb\[2\]\.connect/dsdpdemodb\[2\]\.connect/g" ${file_name}
	sed -i "s%dsdpdemodb\[2\]\.connect=.*%dsdpdemodb\[2\]\.connect=jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=${db_address_list}(LOAD_BALANCE=no)(FAILOVER=on))(CONNECT_DATA=(SERVICE_NAME=${oracle_info_server_sid})))|${oracle_DSDPDEMOdb_username}|${user_pwd}|10|20|10|10|60000|true|true|3000|select 1 from dual|true|300000|20%g" ${file_name}
	
	sed -i "s%redis.connect=.*%redis.connect=${redis_url}%g" ${file_name}
	
  sed -i "s/#dsdpdemo.monitor.port/dsdpdemo.monitor.port/g" ${file_name1}
	update_cfg_value "${file_name1}" "dsdpdemo.monitor.port" "${demo_local_ip_offset_monitor_port}"
	if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "modify dsdpdemo.monitor.port failed"
        return 1
    fi
  sed -i "s/#dsdpdemo.dsf.port/dsdpdemo.dsf.port/g" ${file_name1}
	update_cfg_value "${file_name1}" "dsdpdemo.dsf.port" "${dsdpdemo_service_port}"
	if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "dsdpdemo.dsf.port failed"
        return 1
    fi
  sed -i "s/#commons.log.serverIp/commons.log.serverIp/g" ${file_name1}
	update_cfg_value "${file_name1}" "commons.log.serverIp" "${demo_local_ip}"
	if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "modify commons.log.serverIp failed"
        return 1
    fi
  sed -i "s/#commons.log.serverPort/commons.log.serverPort/g" ${file_name1}
  
	update_cfg_value "${file_name1}" "commons.log.serverPort" "${demo_local_ip_offset_logserver_port}"
	if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "modify commons.log.serverPort failed"
        return 1
    fi
	
	update_cfg_value "${file_name1}" "dsdpdemo.localIP" "${demo_local_ip}"
	if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "modify dsdpdemo.localIP failed"
        return 1
    fi
	
}

################################################
#            Modify conf/dsf.properties        #
################################################
function modify_demo_dsf
{

   sed -i "s#zk.server.url.*#zk.server.url=${zk_ip_config}#g" ${dsf_file_path}
   update_cfg_value "${dsf_file_path}" "dsf.protocol.tcp.address" "${demo_local_ip}:${dsdpdemo_service_port}"
   update_cfg_value "${dsf_file_path}" "rpc.address" "${demo_local_ip}:${demo_usf_server_port}"
	#dsf auth password
	 read_value "dsf_auth_password"
        if [ $? -ne 0 ]; then
           install_log "ERROR" "DSDP_DEMO" "read dsf_auth_password failed."
           return 1
        else

          typeset dsf_auth_password="${RETURN[0]}"
           decodePwd "${dsf_auth_password}"
           if [ $? -ne 0 ] ; then
           install_log "ERROR" "DSDP_DEMO" "decodePwd dsf failed."
           return 1
           fi
           dsf_auth_pwd="${RETURN[0]}"
           install_log "INFO" "DSDP_DEMO" "decodePwd successful!"
           install_log "INFO" "DSDP_DEMO" " start encodepwd !"


		  
         ################################################################
		 #modif key and password start		
         #typeset dsf_server_encode=$(./encryptServer.sh 0 ${ dsf_auth_pwd })			 
		 cd ${HOME}/dsdpdemo_container/bin
		 typeset dsf_server_encode=$((echo ${dsf_auth_pwd};echo)|./encryptPwd.sh 0)	
		 if [ $? -ne 0 ] ; then
            install_log "ERROR" "DSDP_DEMO" "encodePwd server failed."
            return 1
         fi
		 
	    tmpServerPort=`echo "${dsf_server_encode}"|awk -F ' ' '{print $1}'`

		
        serverPort=${tmpServerPort##*Key:}

        serverPassword=${dsf_server_encode#*Password:}

		#modify dsf password
        dsf_server_encode=${serverPassword}
		
	    grep -qe 'bme.encryption.key' ${bme_secretkey_file_path}
    
	    #not exist ,add
	    if [ $? -ne 0 ]
        then
	    {
	       echo "bme.encryption.key=${serverPort}" >>  ${bme_secretkey_file_path}
	    }
	    else
	    {
		
		#modify the bme.secretkey.properties bme.encryption.key
		sed -i "s#^bme\.encryption\.key=.*#bme\.encryption\.key=${serverPort}#g" ${bme_secretkey_file_path}
		}
		fi
	    
        dsf_server_pwd="${dsf_server_encode}"
		#modif key and password end		
		################################################################  
		
		   
		   
		   
         cd -
         install_log "INFO" "DSDP_DEMO" "encodePwd successful!"
         fi
		read_value "dsf_auth_switch"
	    if [ $? -ne 0 ]; then
			install_log "ERROR" "DSDP_DEMO" "read value dsf_auth_switch failed."
			return 1
		fi
		dsf_auth_switch="${RETURN[0]}"
		
		sed -i "s#^dsf\.rpc\.login\.identity.*#dsf\.rpc\.login\.identity=${dsf_server_pwd}#g" ${dsf_file_path}

	    sed -i "s#^dsf\.authentication\.enable.*#dsf\.authentication\.enable=${dsf_auth_switch}#g" ${dsf_file_path}

}


function modify_demo_zk
{
	install_log "INFO" "DEMO" "start modify zk-cluster config."

	typeset file_name=${demo_home}/conf/dsdpdemo.zk-cluster.xml
	
	typeset temp_zk_url="${zk_ip_config}"
	
	update_xml_tag_spec "${file_name}" "cluster/connector/url" "name=dsdpdemo.configerZKClient" "$temp_zk_url" 
	
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "update_xml_tag_spec cluster/connector/url failed."
		return 1
	fi
	return 0
}
################################################
#           modify monitor/ module.properties  #
################################################
function modify_clusterid_info 
{ 
	install_log "INFO" "DEMO" "start modify modify_clusterid_info." 
	typeset module_file_name=${HOME}/ideploy/dsdpdemo/script/monitor/module.properties 
	typeset current_time=`date +'%Y%m%d%H%M%S'`
	typeset content_cluster_id="002081210"
	update_cfg_value "$module_file_name" "moduleCode" "${content_cluster_id}${current_time}0001" 
	update_cfg_value "$module_file_name" "moduleIP" "${demo_local_ip}" 
	
	if [ $? -ne 0 ];
		then install_log "ERROR" "DEMO" "modify module.propertie failed" 
		return 1 
	fi 
}
################################################
#           modify version relative         #
################################################
function modify_version_info
{
        install_log "INFO" "DEMO" "start modify version info."
        typeset date=$(date +%Y-%m-%d)

        typeset file_name=${demo_home}/version/platform-dsdpdemo-version.cfg
        sed -i "1s/$/|${date}/" ${file_name}
        if [ $? -ne 0 ];then
        install_log "ERROR" "DEMO" "sed platform-dsdpdemo-version.cfg failed"
        return 1
        fi
}

##########################################################
#         ������ɵ������У����޸�������module.xml       #
##########################################################
function move_to_container
{
	install_log "INFO" "dsdpdemo" "start to integrate component to micro-container."
	dos2unix -r $HOME/dsdpdemo/conf/*	
	dos2unix ${HOME}/ideploy/dsdpdemo/script/module.properties
	typeset file_name=${HOME}/ideploy/dsdpdemo/script/module.properties	
			
	#�������������
	cd ${HOME}	
	cp  -R dsdpdemo ${container_name}/modules/	
	if [ $? -ne 0 ];then
        install_log "ERROR" "dsdpdemo" "copy component to micro-container failed"
        return 1
	fi	
	
	#��ȡ�����ļ�,���ƥ���ע����
	typeset module_name=`cat ${file_name} | grep module_name | grep -v ^# | awk -F= '{print $2}'`
	typeset contextConfigLocation=`cat ${file_name} | grep contextConfigLocation | grep -v ^# | awk -F= '{print $2}'`
	typeset conf_directory=`cat ${file_name} | grep conf-directory | grep -v ^# | awk -F= '{print $2}'`
		
	
	typeset temp_file=${HOME}/ideploy/dsdpdemo/script/temp.properties
	if [ ! -f "${temp_file}" ]; then
		touch "${temp_file}" > "${IDEPLOY_NULL}" 2>&1
		if [ $? -ne 0 ]; then
			install_log ERROR APP_INSTALL "Generating temp_file failed."
			return 1
		fi
	fi	
			
	#generate
	echo "\t<module name=\"${module_name}\">\n" > "${temp_file}"
	echo "\t\t<context-param>\n" >> "${temp_file}"
	echo "\t\t\t<param-name>contextConfigLocation</param-name>\n" >> "${temp_file}"
	echo "\t\t\t<param-value>\n" >> "${temp_file}"
	echo "\t\t\t\t${contextConfigLocation}\n" >> "${temp_file}"
	echo "\t\t\t</param-value>\n" >> "${temp_file}"
	echo "\t\t</context-param>\n" >> "${temp_file}"
	echo "\t\t\t<startupclass>com.huawei.csc.container.adapter.StandaloneContainer</startupclass>\n" >> "${temp_file}"
	echo "\t\t<conf-directory>${conf_directory}</conf-directory>\n" >> "${temp_file}"
	echo "\t</module>\n" >> "${temp_file}"

	#��������module.xml�ļ���ҵ���������ļ�module.properties�����λ��
	typeset line_number=`cat -n ${HOME}/${container_name}/conf/module.xml | grep \<modules\> | awk '{printf "%s",$1}'`	
	if [ $? -ne 0 ];then
        install_log "ERROR" "dsdpdemo" "find the insert line: $line_number"
        return 1
	fi
	
	#������������ļ�д����������module.xml
	sed -i "${line_number} r ${temp_file}" ${HOME}/${container_name}/conf/module.xml
	if [ $? -ne 0 ];then
        install_log "ERROR" "dsdpdemo" "modify module.xml failed"
        return 1
	fi	
	
	rm -rf ${temp_file}
	
}

##########################################################
#      ��ȡup_small.ini�������õ��������                #
##########################################################
function get_container_name
{
	typeset ne_rela_config="${IDEPLOY_PKG_PATH}/script/up_small.ini"
	cfg_get_sec_key_value "${ne_rela_config}" "Component_Container_Relation" "DSDPDEMO"
    if [ $? -ne 0 ]
    then 
		install_log ERROR LIB "Getting the key dsdpdemo in segment Component_Container_Relation of ${ne_rela_config} failed."
		return 1 
	fi
	container_name="${RETURN[0]}"
}

##########################################################
#      设置加解密的工具路径                              #
##########################################################
function set_dbtools_home
{
	dbtools_script_home=${HOME}/${container_name}/bin
	dbtools_lib_home=${HOME}/${container_name}/bin/tools
}

##########################################################
#     �޸��������˿�                #
##########################################################
function modify_jmx_port
{
	typeset jmx_conf_file="${HOME}/${container_name}/conf/csc.properties"
	update_cfg_value "${jmx_conf_file}" "com.huawei.csc.container.jmx.port" "${jmx_port}"
    if [ $? -ne 0 ]
    then 
		install_log ERROR LIB "modify_jmx_port failed."
		return 1 
	fi
}

################################################
#  Annotation   properties                     #
################################################
function annotate_properties 
{
	install_log "INFO" "DEMO" "start annotate conf properties."

	#typeset file_name=${demo_home}/conf/enterprise.dsdpdemo.resource.properties
	
	typeset file_localResource=${demo_home}/conf/enterprise.dsdpdemo.localResource.properties
	typeset file_resource=${demo_home}/conf/enterprise.dsdpdemo.resource.properties
	typeset file_serviceConfig=${demo_home}/conf/enterprise.dsdpdemo.serviceConfig.properties
	typeset file_update=${demo_home}/conf/enterprise.dsdpdemo.update.properties

	awk '{if (demostr($0,1,1)=="#") {print $0} else {print "#"$0}}' "${file_localResource}" > ${demo_home}/conf/temp.properties
	mv ${demo_home}/conf/temp.properties "${file_localResource}"
	
	awk '{if (demostr($0,1,1)=="#") {print $0} else {print "#"$0}}' "${file_resource}" > ${demo_home}/conf/temp.properties
	mv ${demo_home}/conf/temp.properties "${file_resource}"
	
	awk '{if (demostr($0,1,1)=="#") {print $0} else {print "#"$0}}' "${file_serviceConfig}" > ${demo_home}/conf/temp.properties
	mv ${demo_home}/conf/temp.properties "${file_serviceConfig}"
	
	awk '{if (demostr($0,1,1)=="#") {print $0} else {print "#"$0}}' "${file_update}" > ${demo_home}/conf/temp.properties
	mv ${demo_home}/conf/temp.properties "${file_update}"
	
}


#################################################
#           modify .cshrc                       #
#################################################

function modify_demo_cshrc
{
	return 0
	install_log "INFO" "DEMO" "start modify .cshrc."

	#read_value "db_oracle_home"
	get_oracle_home
	if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "get_oracle_home failed."
		return 1
	else
		db_oracle_home="${RETURN[0]}"
		modify_cshrc $db_oracle_home "${demo_home}";
		#modify_cshrc_java_home $JAVA_HOME "${so_home}";
	fi
}
typeset container_name
typeset db_address_list=""
typeset net_ip
typeset n=0
typeset tmp=0
typeset redis_service_url
typeset redis_service_url_size
typeset oracle_user_pwd
typeset demo_local_ip
typeset dsdpdemo_service_port
typeset zk_ip
typeset zk_port 
typeset zk_ip_config
typeset zk_port_config  
typeset redis_url
typeset redisaddr
typeset redis_ip
typeset redis_port
typeset oracle_info_dbuser_compment_ref
typeset oracle_info_server_ip
typeset oracle_info_server_sid
typeset oracle_info_server_port
typeset oracle_DSDPDEMOdb_username
typeset oracle_DSDPDEMOdb_password
typeset user_pwd
typeset dsf_server_pwd
typeset dsf_client_pwd
typeset zk_auth_switch
typeset dsf_auth_switch
typeset demo_home=$HOME/dsdpdemo
typeset cipher_path=$HOME/dsdpdemo/conf/.itpaas.cipher.properties
typeset itpaas_path=$HOME/dsdpdemo/conf/itpaas.properties
typeset dsdpdemo_port
typeset keyfactor_cbc="${HOME}/dsdpdemo_container/bin/tools/CBC/encryption/conf/keyfactor.properties"
typeset keyfactor_checksametools="${HOME}/dsdpdemo_container/bin/tools/CheckSameTools/conf/keyfactor.properties"
typeset keyfactor_conf="${HOME}/dsdpdemo/conf/keyfactor.properties"
typeset bme_secretkey_file_path="${HOME}/dsdpdemo/conf/bme.secretkey.properties"
typeset dsf_file_path="${HOME}/dsdpdemo/conf/dsf.properties"
typeset dbtools_script_home
typeset dbtools_lib_home


get_container_name
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "get_container_name failed."
		return 1
fi

modify_factor_info
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_factor_info failed."
		return 1
fi
set_dbtools_home
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "set_dbtools_home failed."
		return 1
fi

read_base_info
if [ $? -ne 0 ]; then
	install_log "ERROR" "DEMO" "read base info failed."
	return 1
fi


modify_localResource
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_localResource failed."
		return 1
fi
modify_demo_dsf
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_demo_dsf failed."
		return 1
fi

modify_demo_zk
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_demo_zk failed."
		return 1
fi

modify_clusterid_info
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_clusterid_info failed."
		return 1
fi

modify_version_info
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_version_info failed."
		return 1
fi

move_to_container
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "move_to_container failed."
		return 1
fi

modify_jmx_port
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "modify_jmx_port failed."
		return 1
fi

modify_env
if [ $? -ne 0 ] ; then
		install_log "ERROR" "DEMO" "exec modify_env failed."
		return 1
fi

typeset register_monitor_dir=$HOME/ideploy/dsdpdemo/script/monitor

$HOME/bin/register_uniAgent.sh  dsdpdemo "${register_monitor_dir}"

typeset register_comp_file=$HOME/ideploy/dsdpdemo/script/dsdpdemo_comp.cfg

$HOME/bin/register_comp.sh "${register_comp_file}"
if [ $? -ne 0 ];then
		install_log "ERROR" "DEMO" "register comp failed."
	return 1
fi

$HOME/bin/logagent.sh dsdpdemo
rm -rf $HOME/dsdpdemo
rm -rf ${HOME}/${container_name}/lib/usr
rm -rf ${HOME}/${container_name}/modules/dsdpdemo/tools

