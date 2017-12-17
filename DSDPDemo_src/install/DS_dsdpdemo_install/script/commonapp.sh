#!/usr/bin/ksh

##############################################################################
function getsubsyslst
{
	RETURN[0]=""
	for subn in ${subsys}
	do
		if [ "x$subn" = "xhdm" ];then
			if [ -d "${HOME}/tomcat-hdm" ]; then
				if [ "x${RETURN[0]}" = "x" ]; then
					RETURN[0]="${subn}"
				else
					RETURN[0]="${RETURN[0]} ${subn}"
				fi
			fi
		fi
		if [ -d "${HOME}/${subn}" ]; then
			if [ "x${RETURN[0]}" = "x" ]; then
				RETURN[0]="${subn}"
			else
				RETURN[0]="${RETURN[0]} ${subn}"
			fi
		fi
	done
	subsys="${RETURN[0]}"
	return 0
}
##############################################################################
function showhelp
{
	getsubsyslst
	
	if [ "${alias_name}" = "lic" ];then
		echo "Usage: ${alias_name} [subsystem]"
		echo "  The valid subsystem is:  bfm bms cms cmsgw sis search"
	else
		echo "Usage: ${alias_name} [subsystem]"
		echo "  The valid subsystem is: ${RETURN[0]} all"
	fi
	
	return 0
}
##############################################################################
#  ++++  stop app function section ++++
#  ++++  stop app function section ++++
##############################################################################
function stop_apache
{
	typeset status=`ps -fu ${LOGNAME}|grep "httpd"|grep -v "grep"`
	if [ "x${status}" = "x" ]; then
		echo "${ftp_name} application has already been stopped"
		return 0
	fi

	${HOME}/apache/stop.sh >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "stop apache application failed"
	else
		echo "stop apache application successfully"
	fi
}
##############################################################################
function stop_redis
{
        typeset stopfile="${HOME}/redis/redis/stopsrv.sh"
        typeset username=$(whoami)
        typeset pstmp=$(ps -fu ${username} | grep -w 'redis-server' | grep -v grep | awk '{print $2}')

        if [ "x${pstmp}" = "x" ]; then
                echo "INFO" "redis" "redis has already been stopped."
                return 0
        fi

        #install_progress "50"
		${stopfile} >/dev/null 2>&1
        sleep 3

        pstmp=$(ps -fu ${username} | grep -w 'redis-server' | grep -v 'grep' | awk '{print $2}')
        if [ "x${pstmp}" != "x" ]; then
                kill -9 ${pstmp}
                echo "WARN" "redis" "redis has been unconventionality stoped."
        fi

        echo "INFO" "redis" "stop redis complete."

}


##############################################################################
function stop_up
{
	ne_name=$1
	typeset ne_name_tmp=""
	
	if [ "x${ne_name}" = "xzookeeper" ]; then
		ne_name_tmp="zk"
	elif [ "x${ne_name}" = "xactivemq" ]; then
		ne_name_tmp="mq"
	else
		ne_name_tmp=${ne_name}
	fi
	
	if [ -f $HOME/${ne_name}/bin/${ne_name_tmp}_status.sh ];then
		$HOME/${ne_name}/bin/${ne_name_tmp}_status.sh 1>$HOME/${ne_name}/bin/status.log 2>&1
		grep "is stoped" $HOME/${ne_name}/bin/status.log >/dev/null 2>&1
		if [ $? -eq 0 ];then
			echo "${ne_name} is stoped"
		else
			${HOME}/${ne_name}/bin/${ne_name_tmp}_stop.sh 
			if [ $? -ne 0 ]; then
				echo "stop ${ne_name} application failed"
			else
				echo "stop ${ne_name} application successfully"
			fi
		fi
		rm $HOME/${ne_name}/bin/status.log >/dev/null 2>&1
	fi	
}

################################################################################
function stop_slb
{
	${HOME}/slb/slb/slbadmin status | grep -i "OFFLINE" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "slb has already been stopped"
	else 
		${HOME}/slb/bin/stop.sh >/dev/null 2>&1
		echo "stop slb successfully"
	fi	
}
################################################################################
function stop_uoa
{
	typeset status=`${HOME}/uoa/shell/uoa_ps.sh|grep "uoa_lma"`
	if [ "x${status}" = "x" ]; then
		echo "uoa application has already been stopped"
		return 0
	fi

	echo y | ${HOME}/uoa/shell/uoa_stop.sh >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "stop uoa application failed"
	else
		echo "stop uoa application successfully"
	fi
}
################################################################################
function stop_mq
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	typeset tomcat_cmd=$(ps -ef | grep ${LOGNAME} | grep "j2se/jre/bin/java.*" | grep -v grep | grep "tomcat-mq" | awk '{print $2}')
	if [ "x${tomcat_cmd}" = "x" ]; then
		echo "mq has already been stopped"
	else 
		${HOME}/mq/tomcat-mq/bin/mq_stop.sh >/dev/null 2>&1
		typeset tomcat_pid=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/mq/tomcat-mq/jdk1.6.0_29/jre/bin/java.*" | grep -v grep | grep "tomcat-mq" | awk '{print $2}')
		if [ "x${tomcat_pid}" != "x" ];then
			kill -9 ${tomcat_pid}
		fi
		typeset tomcat_cmd=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/mq/tomcat-mq/jdk1.6.0_29/jre/bin/java.*" | grep -v grep | grep "tomcat-mq" | awk '{print $2}')
		if [ "x${tomcat_cmd}" != "x" ]; then
			echo "stop mq failed"
		else
			echo "stop mq successfully"
		fi
	fi	
}
################################################################################
function stop_cgwadapter
{
	${HOME}/cgwadapter/bin/stop_app.sh >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "stop cgwadapter failed"
	else
		echo "stop cgwadapter successfully"
	fi
}

################################################################################
function stop_cgw
{
	typeset sa_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/bin/sa -t 10 -n" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
	typeset so_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/jdk1.6.0_29/bin/java" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)
	typeset dr_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/bin/sa -t 40 -n" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
	
	if [ "x${sa_pro}" == "x0" -a "x${so_pro}" == "x0" -a "x${dr_pro}" == "x0" ];then
		echo "cgw has already been stopped."
	else
		echo "stoping cgw,please wait ..."
		${HOME}/cgw/bin/stopcgw.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 5
			typeset sa_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/bin/sa -t 10 -n" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
			typeset so_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/jdk1.6.0_29/bin/java" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)
			typeset dr_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cgw/bin/sa -t 40 -n" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
			if [ "x${sa_pro_after}" == "x0" -a "x${so_pro_after}" == "x0" -a "x${dr_pro_after}" == "x0" ];then
				echo "Stop cgw successfully."
			else
				echo "Stop cgw failed."
			fi  
		fi
	fi
}

#################################################################################
function stop_smpa
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	pro_name="smpa"
	typeset sa_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa/bin/sa" | grep -v "grep"|awk '{print $2}'| wc -l)
	typeset so_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa" | grep "com.huawei.sgp.so.nodeType" |grep -v "grep" | awk '{print $2}'| wc -l)
	
	if [ "x${sa_pro}" == "x0" -a "x${so_pro}" == "x0" ];then
		echo "${pro_name} has already been stopped."
	else
		echo "stoping ${pro_name},please wait ..."
		${HOME}/${pro_name}/bin/stop${pro_name}.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 10
			typeset sa_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa/bin/sa" | grep -v "grep"|awk '{print $2}'| wc -l)
			typeset so_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa" | grep "com.huawei.sgp.so.nodeType" |grep -v "grep" | awk '{print $2}'| wc -l)
			if [ "x${sa_pro_after}" == "x0" -a "x${so_pro_after}" == "x0" ];then
				echo "Stop ${pro_name} successfully."
			else
				echo "Stop ${pro_name} failed."
			fi  
		fi
	fi
}
#############################################################################
function stop_slcc
{
	typeset status=`slccstatus|grep "is running"`
	if [ "x${status}" = "x" ]; then
		echo "Application has already been stopped"
		return 0
	fi

	stopslcc >slcc.log 2>&1
	typeset is_error=`grep "Process.*is running" slcc.log`
	if [ "x${is_error}" != "x" ]; then
		echo "stop slcc application failed"
	else
		echo "stop slcc application successfully"
	fi

	rm slcc.log
}
##############################################################################
function stop_chg
{
	pro_name="$1"	
	if [ ! -f ${HOME}/${pro_name}/bin/stop.sh ];then
		echo "it may be chg standby machine, no need to stop cbe."
		return 0
	fi
	typeset status=`${HOME}/${pro_name}/bin/procs.sh|wc -l`
	if [ ${status} -eq 1 ]; then
		echo "${pro_name} application has already been stoped"
		return 0
	fi

	if [ "x${pro_name}" = "xsmdb" ];then
		${HOME}/${pro_name}/bin/stop_mdb.sh >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop ${pro_name} application failed"
			return 1
		else
			echo "stop ${pro_name} application successfully"
			return 0
		fi		
	fi
	${HOME}/${pro_name}/bin/stop.sh -a >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "stop ${pro_name} application failed"
		return 1
	else
		echo "stop ${pro_name} application successfully"
		return 0
	fi
}
################################################################################
function stop_datastation
{
	typeset datastaion_path="${HOME}/bcvt/datastation"
	if [ ! -d ${datastaion_path} ];then
		return 0
	fi 
	typeset status=`${HOME}/bcvt/datastation/scripts/dststatus.sh|grep "datastation"`
	if [ "x${status}" = "x" ]; then
		echo "datastation has already been stopped"
	else
		${HOME}/bcvt/datastation/scripts/dststop.sh > /dev/null
		sleep 2
		typeset status=`${HOME}/bcvt/datastation/scripts/dststatus.sh|grep "datastation"`
		if [ "x${status}" != "x" ]; then
			echo "stop Datastation failed"
			return 1
		else
			echo "stop Datastation successfully"
		fi
	fi
}

################################################################################
function stop_cm
{
	typeset sa_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/bin/sa" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
	typeset so_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/jdk1.6.0_29/bin/java" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)

	if [ "x${sa_pro}" == "x0" -a "x${so_pro}" == "x0" ];then
			echo "cm has already been stopped."
	else
		echo "stoping cm, please wait ..."
		${HOME}/cm/bin/stopcm.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 5
			typeset sa_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/bin/sa" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
			typeset so_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/jdk1.6.0_29/bin/java" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)
			if [ "x${sa_pro_after}" == "x0" -a "x${so_pro_after}" == "x0" ];then
				echo "Stop cm successfully."
			else
				echo "Stop cm failed."
			fi
		fi
	fi
}
################################################################################
function stop_tomcat
{
	tomcat_name="$1"
	typeset tomcat_cmd=$(ps -fu $LOGNAME | grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep | grep "tomcat-${tomcat_name}"|awk '{print $2}')
	if [ "x${tomcat_cmd}" = "x" ]; then
		echo "${tomcat_name} has already been stopped"
	else 
		${HOME}/${tomcat_name}/tomcat-${tomcat_name}/bin/shutdown.sh >/dev/null 2>&1
		sleep 12
		typeset tomcat_pid=$(ps -fu $LOGNAME |grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep |grep "tomcat-${tomcat_name}" | awk '{print $2}')
		if [ "x${tomcat_pid}" != "x" ];then
			kill -9 ${tomcat_pid}
		fi
		sleep 3
		typeset tomcat_cmd=$(ps -fu $LOGNAME |grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep |grep "tomcat-${tomcat_name}" | awk '{print $2}')
		if [ "x${tomcat_cmd}" != "x" ]; then
			echo "stop ${tomcat_name} failed"
		else
			echo "stop ${tomcat_name} successfully"
		fi
	fi
}

################################################################################
function stop_hdm
{
	typeset hdm_path="${HOME}/tomcat-hdm/bin"
	if [ ! -d ${hdm_path} ];then
		return 0
	fi 
	typeset hdm_cmd=$(ps -fu $LOGNAME | grep -w 'tomcat-hdm' | grep java | grep -v grep |awk '{print $2}')
	if [ "x${hdm_cmd}" = "x" ]; then
		echo "hdm has already been stopped"
	else 
		${HOME}/tomcat-hdm/bin/shutdown.sh >/dev/null 2>&1
		sleep 20
		typeset hdm_cmd=$(ps -fu $LOGNAME |grep -w 'tomcat-hdm' | grep 'java' | grep -v grep | awk '{print $2}')
		if [ "x${hdm_cmd}" != "x" ]; then
			echo "stop hdm failed"			
			echo "now force to stop hdm tomcat"
			kill -9 ${hdm_cmd}
			echo "stop hdm successfully"
		else
			echo "stop hdm successfully"
		fi
	fi
}
################################################################################
function stop_java_comp
{
	java_comp_name="$1"
	if [ -d "${HOME}/${java_comp_name}/tomcat/bin" ];then
		java_container="tomcat"
		stop_sh="${HOME}/${java_comp_name}/tomcat/bin/shutdown.sh"
		typeset status=$(ps -fu $LOGNAME | grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep | grep "${java_comp_name}"|awk '{print $2}')
	else
		java_container="jboss"
		stop_sh="${HOME}/${java_comp_name}/jboss/bin/stop.sh"
		typeset status=`${HOME}/${java_comp_name}/tools/proc.sh`
	fi

	if [ "x${status}" = "x" ]; then
		echo "${java_comp_name} ${java_container} process has already been stopped"
	else
		${stop_sh} >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop ${java_comp_name} ${java_container} process failed"
			return 1
		else
			echo "stop ${java_comp_name} ${java_container} application successfully"
		fi
	fi
}
################################################################################
function stop_java_monitor
{
	${HOME}/monitor/bin/status_monitor | grep "mdspmon"  >/dev/null
	if [ $? -eq 0 ]; then 
		${HOME}/monitor/bin/kill.sh mdspmon 1>/dev/null 2>&1 
		if [ $? -ne 0 ]; then
			echo "stop monitor failed"
			return 1 
		fi
		echo "stop monitor successfully"
	else
		echo "monitor has been stopped."
	fi
	
	return 0
}
###############################################################################
function stop_lcap_uoa
{
	ps -ef | grep ${LOGNAME} | grep "uoa_lma" | grep -v "grep"  >/dev/null 
	if [ $? -eq 0 ];then
		echo y|${HOME}/lcap_uoa/shell/uoa_stop.sh 1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop lcap_uoa failed"
		else
			echo "stop lcap_uoa successfully" 
		fi
	else
		echo "lcap_uoa has been stopped"
	fi
}
#################################################################################
function stop_lcpp
{
	ps -ef | grep ${LOGNAME} | grep "lcpp" | grep -v "grep"  | grep -wv $$ | grep -v "rc.sh" >/dev/null
	if [ $? -eq 0 ];then
		${HOME}/lcpp/shell/stop_lcap.sh
		if [ $? -ne 0 ]; then
			echo "stop lcpp failed"
		else
			echo "stop lcpp successfully"  
		fi
	else
		echo "lcpp has been stopped"
	fi
}
#################################################################################
function stop_lcsm
{
	ps -ef | grep ${LOGNAME} | grep "lcsm" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh" >/dev/null
	if [ $? -eq 0 ];then
		${HOME}/lcsm/shell/stop_lcsm.sh
		if [ $? -ne 0 ]; then
			echo "stop lcsm failed"
		else
			echo "stop lcsm successfully" 
		fi
	else
		echo "lcsm has been stopped"
	fi
}
#################################################################################
function stop_logserver
{
	ps -ef | grep ${LOGNAME} | grep "lcap.exe" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null
	if [ $? -eq 0 ];then
		${HOME}/logserver/LCAP/shell/lcap.bg.web.service stop  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop logserver failed"
		else
			#using the following shell, having problem!!
			#${HOME}/logserver/LOGAUDIT_WEB/bin/shutdown.sh
			 #using the following shell, having problem!!
                        #${HOME}/logserver/LOGAUDIT_WEB/bin/shutdown.sh
            ps -ef|grep "LOGAUDIT_WEB"|grep -v grep |awk '{print $2}' > tmp
            while read PID
            do
                    kill -9 $PID >/dev/null 2>&1
            done < tmp
            rm tmp
            ps -ef|grep "LOGAUDIT_WEB"|grep -v grep
            if [ $? -ne 0 ];then
                    echo "stop logserver successfully" 
            else
                    echo "stop logserver failed"
            fi
		fi
	else
		echo "logserver has been stopped"
	fi
}
#################################################################################
function stop_logtracer
{
	ps -ef | grep ${LOGNAME} | grep "binlogtracer" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null 
	if [ $? -eq 0 ];then
		${HOME}/logtracer/setup/shell/stop_logtracer.sh  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop logtracer failed"
		else
			echo "stop logtracer successfully"
		fi
	else
		echo "logtracer has been stopped"
	fi
}
#################################################################################
function stop_logtracer_manager
{
	ps -ef | grep ${LOGNAME} | grep "process_manager.exe" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null 
	if [ $? -eq 0 ];then
		${HOME}/logtracer_manager/shell/logtracer.service stop  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "stop logtracer_manager failed" 
		else
			echo "stop logtracer_manager successfully"
		fi
	else
		echo "logtracer_manager has been stopped"
	fi
}
##############################################################################
#  ++++  start app function section ++++
#  ++++  start app function section ++++
##############################################################################

function start_slb
{	
	${HOME}/slb/slb/slbadmin status | grep -i "ONLINE" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		#check current slb whether start
		echo "the slb has already been started."
		return 0
	else
		${HOME}/slb/bin/start.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
        	#check current slb whether start
           	echo "Starting slb application successfully."
          	return 0
       	fi
	fi

}

################################################################################
function start_redis
{
        typeset process_name="redis-server"
        typeset redis_path="${HOME}/redis/redis"
        if [ ! -d ${redis_path} ]; then
                echo "ERROR" "redis" "the file ${redis_path} is not exist."
                return 1
        fi

        typeset userstmp=$(whoami)
        typeset pstmp=$(ps -fu "${userstmp}" | grep -w ${process_name} | grep -v 'grep' )

        if [ "x${pstmp}" != "x" ]; then
			echo "INFO" "redis" "redis has already been started."
			return 0
        else
			cd ${redis_path}
			nohup ./startsrv.sh 1>/dev/null 2>&1 &
			if [ $? -ne 0 ]; then
				echo "ERROR" "redis" "execute \"nohup ${redis_path}/startsrv.sh 2>&1 & \" error!"
				return 1
			fi
			echo "INFO" "redis" "the start log is in ${redis_dir}/redis/log/redis-server.log"
			sleep 5

			typeset redis_cmd=$(ps -fu ${userstmp} |grep ${process_name} | grep  -v grep | awk '{print $2}')

			if [ "x${redis_cmd}" = "x" ]; then
				echo "ERROR" "redis" "the redis thread not found, start redis failed!"
				return 1
			fi
        fi

        echo "INFO" "redis" "the redis is started"
        return 0

}

################################################################################
function start_up
{
	ne_name=$1
	typeset ne_name_tmp=""
	
	if [ "x${ne_name}" = "xzookeeper" ]; then
		ne_name_tmp="zk"
	elif [ "x${ne_name}" = "xactivemq" ]; then
		ne_name_tmp="mq"
	else
		ne_name_tmp=${ne_name}
	fi
	
	if [ -f "${HOME}/${ne_name}/bin/${ne_name_tmp}_start.sh" ]; then
		$HOME/${ne_name}/bin/${ne_name_tmp}_status.sh 1>${HOME}/status.log 2>&1
		grep "is running" ${HOME}/status.log >/dev/null 2>&1
		if [ $? -eq 0 ];then
			echo "${ne_name} has already been started."
		else
			#echo "starting ${ne_name},please wait ..."
			${HOME}/${ne_name}/bin/${ne_name_tmp}_start.sh 
			#if [ $? -eq 0 ]; then
			#	sleep 5
			#	$HOME/${ne_name}/bin/${ne_name_tmp}_status.sh 1>${HOME}/status.log 2>&1
			#	grep "is running" ${HOME}/status.log >/dev/null
			#	if [ $? -eq 0 ];then
			#		echo "${ne_name} has already been started."
			#	else
			#		echo "starting ${ne_name},please wait ..." 
			#	fi	
			#fi
		fi
	fi	
	rm ${HOME}/status.log  >/dev/null 2>&1
}
##############################################################################
function start_apache
{
	typeset status=`ps -fu ${LOGNAME}|grep "httpd"|grep -v "grep"`
	if [ "x${status}" != "x" ]; then
		echo "${ftp_name} application has already been started"
		return 0
	fi

	${HOME}/apache/start.sh >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Starting ${ftp_name} application failed"
	else
		echo "Starting ${ftp_name} application successful"
	fi
}
################################################################################
function start_mq
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	typeset tomcat_cmd=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/mq/tomcat-mq/jdk1.6.0_29/jre/bin/java.*" | grep -v grep | grep "tomcat-mq" | awk '{print $2}')
	if [ "x${tomcat_cmd}" != "x" ]; then
		echo "mq application has already been started"
	else
		${HOME}/mq/tomcat-mq/bin/mq_start.sh >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Starting mq application failed"
		else
			sleep 15
			${HOME}/mq/tomcat-mq/bin/mq_status.sh >/dev/null 2>&1
			if [ $? -ne 0 ]; then
				echo "Starting mq application failed"
			else 
				echo "Starting mq application successfully"
			fi	
		fi	
	fi
}
################################################################################
function start_cgwadapter
{
	${HOME}/cgwadapter/bin/start_app.sh >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo  "Starting cgwadapter application failed"
	else     
		echo  "Starting cgwadapter application successfully"
	fi
}
################################################################################
function start_uoa
{
	typeset status=`${HOME}/uoa/shell/uoa_ps.sh|grep "uoa_server"`
	if [ "x${status}" != "x" ]; then
		echo "uoa application has already been started"
		return 0
	fi

	${HOME}/uoa/shell/uoa_start.sh >/dev/null 2>&1

	sleep 7
	typeset is_eoor=`ps -fu ${LOGNAME}|grep "uoa_server"|grep -v "grep"`
	if [ "x${is_eoor}" = "x" ]; then
		echo "Starting uoa application failed"
	else
		echo "Starting uoa application successfully"
	fi

}
################################################################################
function start_cgw
{
	${HOME}/cgw/bin/cgw_status.sh >/dev/null 2>&1
	if [ $? -eq 0 ];then
		echo "cgw has already been started."
	else
		echo "starting cgw,please wait ..."
		${HOME}/cgw/bin/startcgw.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 15
			${HOME}/cgw/bin/cgw_status.sh >/dev/null 2>&1
			if [ $? -eq 0 ];then
				echo "start cgw successfully."
			else
				echo "start cgw failed."
			fi  
		fi
	fi
}
#################################################################################
function start_smpa
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	pro_name="smpa"
	typeset sa_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa/bin/sa" | grep -v "grep"|awk '{print $2}'| wc -l)
	typeset so_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa" | grep "com.huawei.sgp.so.nodeType" |grep -v "grep" | awk '{print $2}'| wc -l)
	
	if [ "x${sa_pro}" != "x0" -a "x${so_pro}" != "x0" ];then
		echo "${pro_name} has already been started."
	else
		echo "starting ${pro_name},please wait ..."
		${HOME}/${pro_name}/bin/start${pro_name}.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 5
			typeset sa_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa/bin/sa" | grep -v "grep"|awk '{print $2}'| wc -l)
			typeset so_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/smpa" | grep "com.huawei.sgp.so.nodeType" |grep -v "grep" | awk '{print $2}'| wc -l)
			if [ "x${sa_pro_after}" != "x0" -a "x${so_pro_after}" != "x0" ];then
				echo "start ${pro_name} successfully."
			else
				echo "start ${pro_name} failed."
			fi  
		fi
	fi
}
#############################################################################
function start_slcc
{
	typeset status=`slccstatus|grep "is stopped"|grep -v "grep"`
	if [ "x${status}" == "x" ]; then
		echo "slcc application has already been started"
		return 0
	fi

	startslcc >slcc.log 2>&1
	if [ $? -ne 0 ]; then
		echo "Start slcc application failed"
	else
		echo "Start slcc application successfully"
	fi

	rm slcc.log

}
##############################################################################
function start_chg
{
	pro_name="$1"	
	if [ ! -f ${HOME}/${pro_name}/bin/procs.sh ];then
		echo "it may be chg standby machine, no need to start cbe."
		return 0
	fi
	
	typeset status=`${HOME}/${pro_name}/bin/procs.sh|wc -l`
	if [ ${status} -gt 1 ]; then
		echo "${pro_name} application has already been started"
		return 0
	fi

	if [ "x${pro_name}" = "xsmdb" ];then
		${HOME}/${pro_name}/bin/start_mdb.sh >/dev/null 2>&1
		sleep 5
		typeset mdb_pmon=`ps -fu $LOGNAME | grep mdb_pmon | grep -v grep`
		if [ "x${mdb_pmon}" = "x" ]; then
			echo "Starting ${pro_name} application failed"
			return 1
		else
			echo "Starting ${pro_name} application successfully"
			return 0
		fi
	fi

	${HOME}/${pro_name}/bin/start.sh -a >/dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "Starting ${pro_name} application failed"
		return 1
	else
		echo "Starting ${pro_name} application successfully"
		return 0
	fi
}
################################################################################
function start_datastation
{
	typeset datastaion_path="${HOME}/bcvt/datastation"
	if [ ! -d ${datastaion_path} ];then
		return 0
	fi 
	typeset status=`${HOME}/bcvt/datastation/scripts/dststatus.sh|grep "datastation"`
	if [ "x${status}" != "x" ]; then
		echo "datastation has already been started"
	else
		${HOME}/bcvt/datastation/scripts/dststart.sh > /dev/null
		sleep 2
		typeset status=`${HOME}/bcvt/datastation/scripts/dststatus.sh|grep "datastation"`
		if [ "x${status}" = "x" ]; then
			echo "Starting Datastation failed"
			return 1
		else
			echo "Starting Datastation successfully"
		fi
	fi
}
################################################################################
function start_cm
{
	typeset sa_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/bin/sa" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
	typeset so_pro=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/jdk1.6.0_29/bin/java" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)
	if [ "x${sa_pro}" == "x1" -a "x${so_pro}" == "x1" ];then
		echo "cm has already been started."
	else
		echo "starting cm,please wait ..."
		${HOME}/cm/bin/startcm.sh >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			sleep 5
			${HOME}/cm/bin/cm_status.sh >/dev/null 2>&1
			if [ $? -eq 0 ];then
					echo "start cm successfully."
			else
					echo "start cm failed."
			fi
		fi
	fi
}
################################################################################
function start_hdm
{
	typeset process_name="tomcat-hdm"
	typeset hdm_path="${HOME}/tomcat-hdm/bin"
	if [ ! -d ${hdm_path} ];then
		return 0
	fi 
	chmod 700 ${hdm_path}/*
	typeset userstmp=$(whoami)
	typeset pstmp=$(ps -fu "${userstmp}" | grep -w ${process_name} | grep -v 'grep' )

	if [ "x${pstmp}" != "x" ]; then
		echo "hdm tomcat thread has already been started."
	else
		cd ${hdm_path}
		#for DTS2014070205583, use start.sh instead of start_up.sh
		start_sh="${HOME}/tomcat-hdm/bin/startup.sh"
		new_start_sh="${HOME}/tomcat-hdm/bin/start.sh"
		if [ -f ${new_start_sh} ];then
			start_sh=${new_start_sh}
		fi

		nohup ${start_sh} 1>/dev/null 2>&1 &
		if [ $? -ne 0 ]; then
			echo "execute \"nohup ${start_sh} 2>&1 & \" failed!"
		fi
		echo "the start log is in ${HOME}/tomcat-hdm/logs/catalina.out"
		sleep 5

		typeset hdm_cmd=$(ps -fu ${userstmp} | grep ${process_name} | grep -v grep | awk '{print $2}')
		if [ "x${hdm_cmd}" = "x" ]; then
			echo "the tomcat thread not found, start hdm failed!"
		fi
	fi

	typeset idx=0
	typeset expire_times=100
	while [ ${idx} -lt ${expire_times} ]
	do
		echo "Start tomcat business container, please wait ..."
		((idx=idx+1))
		grep "Server startup" "${HOME}/tomcat-hdm/logs/catalina.out" 1>/dev/null 2>&1
		if [ $? -eq 0 ];then
			echo "Start tomcat business container successfully."
			echo "Start hdm successfully."
			break
		fi
		sleep 3
	done
}
################################################################################
################################################################################
#parameter tomcat name: sso ddr payment billing
################################################################################
function start_tomcat
{
	tomcat_name="$1"
	typeset -i flag=0
	typeset tomcat_cmd=$(ps -fu $LOGNAME | grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep | grep "tomcat-${tomcat_name}"|awk '{print $2}')
	if [ "x${tomcat_cmd}" != "x" ]; then
		echo "${tomcat_name} has already been started"
	else 
		#for DTS2014070205583, use start.sh instead of start_up.sh
		start_sh="${HOME}/${tomcat_name}/tomcat-${tomcat_name}/bin/startup.sh"
		new_start_sh="${HOME}/${tomcat_name}/tomcat-${tomcat_name}/bin/start.sh"
		if [ -f ${new_start_sh} ];then
			start_sh=${new_start_sh}
		fi
		${start_sh} >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Starting ${tomcat_name} failed"
			return 1
		else
			sleep 6
			echo "Starting ${tomcat_name} business container, please wait ..."
			typeset idx=0 
			typeset expire_times=30
			while [ ${idx} -lt ${expire_times} ]
			do
				((idx=idx+1))
				egrep "Server startup|Container Startup" ${HOME}/${tomcat_name}/tomcat-${tomcat_name}/logs/catalina.out >/dev/null 2>&1
				if [ $? -eq 0 ]; then
					echo "Starting ${tomcat_name} successfully"
					flag=1
					break
				fi
				sleep 3
			done
			if [ ${flag} -ne 1 ]; then
				echo "Start ${tomcat_name} failed"
				return 1
			fi
		fi
	fi
}
################################################################################
function start_java_comp
{
	java_comp_name="$1"
	
	if [ -d "${HOME}/${java_comp_name}/tomcat/bin" ];then
		java_container="tomcat"
		start_sh="${HOME}/${java_comp_name}/tomcat/bin/start.sh"
		start_log="${HOME}/${java_comp_name}/tomcat/logs/catalina.out"
		typeset status=$(ps -fu $LOGNAME | grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep | grep "${java_comp_name}"|awk '{print $2}')
	else
		java_container="jboss"
		start_sh="${HOME}/${java_comp_name}/jboss/bin/start.sh"
		start_log="${HOME}/${java_comp_name}/jboss/bin/run.log"
		typeset status=`${HOME}/${java_comp_name}/tools/proc.sh`
	fi
	typeset -i flag=0
	if [ "x${status}" != "x" ]; then
		echo "${java_comp_name} ${java_container} process has already been started"
	else
		${start_sh} >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "Starting ${java_comp_name} ${java_container} process failed"
			return 1
		fi
		
		# avoid test wrong log file
		sleep 1
	fi
	
	typeset idx=0 
	typeset expire_times=100
	
	# for DTS2013111802686, for sis, set expire time 10min(200x3s)
	if [ "x${java_comp_name}"="xsis" ]; then
		expire_times=200
	fi
	
	echo "Starting ${java_comp_name} ${java_container} business container,please wait ..."
	while [ ${idx} -lt ${expire_times} ]
	do
		((idx=idx+1))
		
		# optimize wait time, if jboss start container failed, then break
		grep -i "Closing business container" "${start_log}" >/dev/null 2>&1
		if [ $? -eq 0 ]; then
			flag=0
			break
		fi
		
		grep -x "\*     Business container is started successfully!     \*" "${start_log}" 1>/dev/null 2>&1 
		if [ $? -eq 0 ]; then			
			echo "Starting ${java_comp_name} ${java_container} successfully"
			flag=1
			break 
		fi
		sleep 3
	done
	
	if [ ${flag} -ne 1 ]; then
		echo "Start ${java_comp_name} ${java_container} failed"
		return 1
	fi	
}
#################################################################
function start_java_monitor
{
	${HOME}/monitor/bin/status_monitor | grep "mdspmon"  >/dev/null
	if [ $? -ne 0 ]; then 
		${HOME}/monitor/bin/start_monitor 1>/dev/null 2>&1 
		if [ $? -ne 0 ]; then
			echo "Starting java monitor failed"
			return 1 
		fi
		echo "Start monitor successfully"
	else
		echo "monitor has been started."
	fi
	
	return 0
}
#################################################################################
function start_lcap_uoa
{
	ps -ef | grep ${LOGNAME} | grep "uoa_lma" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null
	if [ $? -ne 0 ];then
		${HOME}/lcap_uoa/shell/uoa_start.sh  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start lcap_uoa failed"
		else
			echo "start lcap_uoa successfully" 
		fi
	else
		echo "lcap_uoa has been started"
	fi
}
#################################################################################
function start_lcpp
{
	ps -ef | grep ${LOGNAME} | grep "lcpp" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"   >/dev/null
	if [ $? -ne 0 ];then
		${HOME}/lcpp/shell/start_lcap.sh  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start lcpp failed"
		else
			echo "start lcpp successfully"  
		fi
	else
		echo "lcpp has been started"
	fi
}
#################################################################################
function start_lcsm
{
	ps -ef | grep ${LOGNAME} | grep "lcsm" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null 
	if [ $? -ne 0 ];then
		${HOME}/lcsm/shell/start_lcsm.sh  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start lcsm failed"
		else
			echo "start lcsm successfully" 
		fi
	else
		echo "lcsm has been started"
	fi
}
#################################################################################
function start_logserver
{
	ps -ef | grep ${LOGNAME} | grep "lcap.exe" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null 
	if [ $? -ne 0 ];then
		${HOME}/logserver/LCAP/shell/lcap.bg.web.service start  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start logserver failed"
		else
			#start logserver so slowly
			echo "Please wait for starting ..." 
			sleep 30
			echo "start logserver successfully" 
		fi
	else
		echo "logserver has been started"
	fi
}
#################################################################################
function start_logtracer
{
	ps -ef | grep ${LOGNAME} | grep "binlogtracer" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null 
	if [ $? -ne 0 ];then
		${HOME}/logtracer/setup/shell/start_logtracer.sh  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start logtracer failed"
		else
			echo "start logtracer successfully"
		fi
	else
		echo "logtracer has been started"
	fi
}
#################################################################################
function start_logtracer_manager
{
	ps -ef | grep ${LOGNAME} | grep "process_manager.exe" | grep -v "grep" | grep -wv $$ | grep -v "rc.sh"  >/dev/null
	if [ $? -ne 0 ];then
		${HOME}/logtracer_manager/shell/logtracer.service start  1>/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "start logtracer_manager failed" 
		else
			echo "start logtracer_manager successfully"
		fi
	else
		echo "logtracer_manager has been started"
	fi
}
##############################################################################
#++++ status app function section ++++
##############################################################################
function status_apache
{
	typeset -i httpd=` ps -fu ${LOGNAME} | grep -v 'grep' | grep "httpd" |sed 's/^[ \t]*//;s/[ \t\r]*$//' |wc -l`
	if [ "x${httpd}" = "x0" ]; then	
		echo "Process:           apache is stopped!!!."
	else
		echo "Process:           apache is running."    
	fi
}

##############################################################################
function status_slb
{
	${HOME}/slb/slb/slbadmin status | grep -i "OFFLINE" >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "Process:              slb is stopped!!!."
	else 
		echo "Process:              slb is running."
	fi	
}
################################################################################
function status_up
{
	ne_name=$1
	typeset ne_name_tmp=""
	
	if [ "x${ne_name}" = "xzookeeper" ]; then
		ne_name_tmp="zk"
	elif [ "x${ne_name}" = "xactivemq" ]; then
		ne_name_tmp="mq"
	else
		ne_name_tmp=${ne_name}
	fi
	
	if [ -f $HOME/${ne_name}/bin/${ne_name_tmp}_status.sh ];then
		$HOME/${ne_name}/bin/${ne_name_tmp}_status.sh >${HOME}/status.log 2>&1
		grep "is running" ${HOME}/status.log >/dev/null 2>&1
		if [ $? -eq 0 ];then
			echo "Process:            ${ne_name} is running."
		else
			echo "Process:            ${ne_name} is stopped."
		fi
		rm ${HOME}/status.log >/dev/null 2>&1
	fi	
}
################################################################################
function status_mq
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	${HOME}/mq/tomcat-mq/bin/mq_status.sh |grep "MQ is running." >/dev/null 2>&1
	if [ $? -ne 0 ]; then	
		echo "Process:              mq is stopped!!!."
	else
		echo "Process:              mq is running."    
	fi
}
################################################################################
function status_cgwadapter
{
	${HOME}/cgwadapter/bin/status_app.sh >/dev/null 2>&1
	if [ $? -ne 0 ]; then	
		echo "Process:              cgwadapter is stopped!!!."
	else
		echo "Process:              cgwadapter is running."    
	fi
}
################################################################################
function status_uoa
{
	typeset proc_list=$(grep "^ProcName" ${HOME}/uoa/cfg/uoa_lma.ini|awk -F= '{print $2}'|sed 's/^[ \t]*//;s/[ \t\r]*$//' )
	proc_list="${proc_list}"
	typeset process=$(${HOME}/uoa/shell/uoa_ps.sh|grep -i "uoa_lma has not exist")
	if [ "x${process}" != "x" ]; then
			awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:","uoa_lma","is stopped"}'
	else
			awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:","uoa_lma","is running"}'
	fi

	for key in ${proc_list}
	do
			process=$(${HOME}/uoa/shell/uoa_ps.sh|grep -wi "${key}")
			if [ "x${process}" = "x" ]; then
					awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:",pr,"is stopped"}'
			else
					awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:",pr,"is running"}'
			fi
	done

}

#################################################################################
function status_cgw
{
	echo_status_cgw "sa"
	echo_status_cgw "so"
	echo_status_cgw "dr"
}

#################################################################################
function echo_status_cgw
{
	typeset comp_cgw="$1"
	$HOME/cgw/bin/cgw_status.sh 1>status.log 2>&1
	grep "${comp_cgw}" status.log  > status_cgw_tmp.log
	
	while read comp_pro
	do
		echo "Process:            ${comp_pro}"
	done < status_cgw_tmp.log

	rm status_cgw_tmp.log
	rm status.log
}

#################################################################################
function status_smpa
{
	typeset cgw_cfg="$HOME/cgw/bin/config.properties"
	if [ -f ${cgw_cfg} ];then
		typeset nodeid=$(awk -F= -v k="SA_NODEID" '{ if ( $1 == k ) print substr($0,(length($1)+2),length($0))}' ${cgw_cfg})
		if [ $nodeid -ne 1 ];then
			return 0
		fi
	fi
	pro_name="smpa"
	$HOME/${pro_name}/bin/${pro_name}_status.sh 1>status.log 2>&1
	grep "is running" status.log >/dev/null
	if [ $? -eq 0 ];then
		echo "Process:            ${pro_name} is running."
	else
		echo "Process:            ${pro_name} is stopped."
	fi
	rm status.log
}
#############################################################################
function status_slcc
{
	slccstatus
}
##############################################################################
function status_cbe
{
	if [ ! -f ${HOME}/cbe/bin/procs.sh ];then
		echo "it may be the standby machine, no need to check cbe status."
		return 0
	fi
	
	get_cbe_service_list
	if [ $? -ne 0 ];then
		echo "get cbe service list failed."
		return 1
	fi
	typeset cbe_list="${RETURN[0]}"

	if [ "x${cbe_list}" == "x" ];then
		echo "it may be the standby machine, no need to check cbe status."
		return 0
	fi
	
	for key in ${cbe_list}
	do
		typeset process=$(${HOME}/cbe/bin/procs.sh|grep -wi "${key}")
		if [ "x${process}" = "x" ]; then
			awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:",pr,"is stopped"}'
		else
			awk -vpr=${key} 'BEGIN {printf "%-10s %-20s %-5s\n","Process:",pr,"is running"}'
		fi
	done

	echo "==========================================="

	typeset serviceadm_list=$(serviceadm -list)
	typeset serviceadm_head=`echo "${serviceadm_list}" | sed -n 1p`
	typeset smstate_seq=0
	typeset smstate_flag=0
	for tmp_head in ${serviceadm_head}
	do
		# Field "IP Address" has a space, looks like 2 fields, avoid this question.
		 if [ "xIP" = "x${tmp_head}" ]; then
			continue
		 fi
		 smstate_seq=`expr ${smstate_seq} + 1`
			
		 if [ "xSMState" = "x${tmp_head}" ]; then
			smstate_flag=1
			break;
		 fi
	done

	if [ ${smstate_flag} = 0 ]; then
		echo "not find keyword SMState."
		return 0
	fi

	typeset state_seq=`expr ${smstate_seq} - 1`
	typeset service_unactive_flag=0
	typeset service_unactive_list=`echo "${serviceadm_list}" | awk '{ if (($'${state_seq}'=="Active")&&($'${smstate_seq}'!="Active")) printf $0"\n" }'`
	if [ "x${service_unactive_list}" != "x" ]; then
		echo "service state is not Active"
	else
		echo "service state is Active"
	fi
}

function get_cbe_service_list
{
	node_cfg="${HOME}/cbe/config/node.cfg"
	if [ ! -f ${node_cfg} ];then
		echo "The file ${node_cfg} doesn't exist, maybe cbe is not installed successfully."
		return 1
	fi
	
	awk 'BEGIN{ ic_b = 0; }
	{
		if ($0 ~ /<!--/)
		{
			# single line comment
			if ($0 ~ /-->/)
			{
				# print uncomment part, before "<!--" and after "-->"
				print substr($0, 1, index($0, "<!--") - 1) substr($0, index($0, "-->") + 3);
				next;
			}
			# multiline comment begin
			else
			{
				# print uncomment part, before "<!--"
				print substr($0, 1, index($0, "<!--") - 1);
				ic_b = NR;
				next;
			}
		}
		
		# multiline comment end
		if (ic_b > 0 && $0 ~ /-->/)
		{
			# print uncomment part, after "-->"
			print substr($0, index($0, "-->") + 3);
			ic_b = 0;
			next;
		}
		
		# whole comment line, skip it
		if (ic_b > 0)
		{
			next;
		}
		
		# print uncomment lines
		print $0;
	}' ${node_cfg} | sed '/^[ \t]*$/d' > node_cfg_res
	
	RETURN[0]=$(grep "aliasName" node_cfg_res | grep -v 'type="eTrace"' | awk '{for (i=1;i<=NF;i++) if ($i ~ /aliasName/) printf "%s%s",$i,"\n"}' | awk -F\" '{print $2}' | uniq)
	
	rm node_cfg_res
	
}
function echo_status
{
    typeset flag="$1"
	typeset comp="$2"
    typeset process=`${HOME}/${comp}/bin/procs.sh|grep -i "$flag"`
    if [ "x${process}" = "x" ]; then
        echo "Process:              $flag is stopped!!!."
    else
        echo "Process:              $flag is running."
    fi
}
function status_smdb
{
	echo_status "mdb_pmon"  "smdb"
	echo_status "mdb_smon"  "smdb"
	echo_status "mdb_oama"  "smdb"	
}
function status_enip
{
	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "icdcomm"`
	if [ "x${process}" = "x" ]; then
		echo "Process:              icdcomm is stopped!!!."
	else
		echo "Process:              icdcomm is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "idcenter"`
	if [ "x${process}" = "x" ]; then
		echo "Process:             idcenter is stopped!!!."
	else
		echo "Process:             idcenter is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "idagent"`
	if [ "x${process}" = "x" ]; then
		echo "Process:              idagent is stopped!!!."
	else
		echo "Process:              idagent is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "configDaemon"`
	if [ "x${process}" = "x" ]; then
		echo "Process:         configDaemon is stopped!!!."
	else
		echo "Process:         configDaemon is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "namingDaemon"`
	if [ "x${process}" = "x" ]; then
		echo "Process:         namingDaemon is stopped!!!."
	else
		echo "Process:         namingDaemon is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "Monitor 0"`
	if [ "x${process}" = "x" ]; then
		echo "Process:            Monitor 0 is stopped!!!."
	else
		echo "Process:            Monitor 0 is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "Center 1"`
	if [ "x${process}" = "x" ]; then
		echo "Process:             Center 1 is stopped!!!."
	else
		echo "Process:             Center 1 is running."
	fi

	typeset process=`${HOME}/enip/bin/procs.sh|grep -i "FetchDataSync 50"`
	if [ "x${process}" = "x" ]; then
		echo "Process:     FetchDataSync 50 is stopped!!!."
	else
		echo "Process:     FetchDataSync 50 is running."
	fi
}

################################################################################
function status_datastation
{
	typeset datastaion_path="${HOME}/bcvt/datastation"
	if [ ! -d ${datastaion_path} ];then
		return 0
	fi 
	dst=`ps -fu $LOGNAME|grep datastation|grep -v "grep"`
	if [ "-x$dst" != "-x" ]; then
		echo "Process:        datastation is running."
	else
		echo "Process:        datastation is stopped!!!"
	fi
}

################################################################################
function status_cm
{
	typeset sa_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm/bin/sa" | grep -v "grep" | awk -F' ' '{print $2}'| wc -l)
	typeset so_pro_after=$(ps -ef | grep ${LOGNAME} | grep "${HOME}/cm" | grep "com.huawei.sgp.so.nodeType" | grep -v "grep"  | awk -F' ' '{print $2}'| wc -l)
	if [ "x${sa_pro_after}" == "x1" -a "x${so_pro_after}" == "x1" ];then
			echo "Process:        cmserver is running."
	else
			echo "Process:        cmserver is stopped!!!"
	fi
}

################################################################################
################################################################################
function status_hdm
{
	typeset hdm_path="${HOME}/tomcat-hdm/bin"
	if [ ! -d ${hdm_path} ];then
		return 0
	fi 
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "org.apache.catalina.startup.Bootstrap" | grep ${HOME}/tomcat-hdm | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            HDM is running."
	else
		echo "Process:            HDM is stopped."
	fi

}

################################################################################
#parameter tomcat name: sso or ddr or payment
################################################################################
function status_tomcat
{
	tomcat_name="$1"
	cmd_name=`ps -fu $LOGNAME |grep "org.apache.catalina.startup.Bootstrap" | grep -v grep|grep "tomcat-${tomcat_name}"`
	if [ "-x${cmd_name}" != "-x" ]; then
		echo "Process:              ${tomcat_name} is running."
	else
		echo "Process:              ${tomcat_name} is stopped!!!."    
	fi

}

################################################################################
function status_java_comp
{
	java_comp_name="$1"
	if [ -d "${HOME}/${java_comp_name}/tomcat/bin" ];then
		java_container="tomcat"
		typeset status=$(ps -fu $LOGNAME | grep "org\.apache\.catalina\.startup\.Bootstrap" | grep -v grep | grep "${java_comp_name}"|awk '{print $2}')
	else
		java_container="jboss"
		typeset status=`${HOME}/${java_comp_name}/tools/proc.sh`
	fi
	
	if [ "-x${status}" != "-x" ]; then
		echo "Process:            ${java_comp_name} ${java_container} is running."
	else
		echo "Process:            ${java_comp_name} ${java_container} is stopped!!!." 
	fi
}

##############################################################################
function status_java_monitor
{
	${HOME}/monitor/bin/status_monitor | grep "mdspmon"  >/dev/null
	if [ $? -eq 0 ]; then 
		echo "Process:           monitor is running."
	else
		echo "Process:           monitor is stopped."
	fi
}

##############################################################################
function status_lcap_uoa
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "uoa_lma" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LCAP_UOA is running."
	else
		echo "Process:            LCAP_UOA is stopped."
	fi
	
}

#################################################################################
function status_lcpp
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "lcpp" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LCPP is running."
	else
		echo "Process:            LCPP is stopped."
	fi
}

#################################################################################
function status_lcsm
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "lcsm" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep"| wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LCSM is running."
	else
		echo "Process:            LCSM is stopped."
	fi
}

#################################################################################
function status_logserver
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "lcap.exe" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LOGSERVER is running."
	else
		echo "Process:            LOGSERVER is stopped."
	fi
}

#################################################################################
function status_logtracer
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "binlogtracer" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LOGTRACER is running."
	else
		echo "Process:            LOGTRACER is stopped."
	fi
}

#################################################################################
function status_redis
{
        typeset check_result=$(ps -ef | grep 'redis-server' | grep -v grep |  wc -l)
        if [ ${check_result} -ne 0 ]; then
                echo "Process:            REDIS is running."
        else
                echo "Process:            REDIS is stopped."
        fi
}


#################################################################################
function status_logtracer_manager
{
	typeset check_result=$(ps -ef | grep ${LOGNAME} | grep "process_manager.exe" | grep -wv $$ | grep -v "rc.sh" | grep -v "grep" | wc -l)
	if [ ${check_result} -ne 0 ]; then 
		echo "Process:            LOGTRACER_MANAGER is running."
	else
		echo "Process:            LOGTRACER_MANAGER is stopped."
	fi
}

subsys="billing monitor bfm sso bms cms ddr cmsgw bcvt sis cgw slcc payment smpa cbe enip smdb uoa cm hdm mq apache cgwadapter lcap_uoa lcpp lcsm logtracer logtracer_manager logserver slb om sa upm sns snsgw activemq zookeeper redis search"