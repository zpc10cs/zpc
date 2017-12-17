#!/bin/sh 
# ****************************************************************************
#                                                                            *
#  monitor.sh: This is for Jaguar Platform                                   *
#                                                                            *
#  Copyright by Huawei Tech. Co., Ltd.                                       *
#  All rights reserved                                                       *
#                                                                            *
# ****************************************************************************
function show_help
{	
	echo "Usage:  MQResumeSendingTool.sh  -d <origCatalog> -f [origFileName] -m [MQconFile] "
	echo "Example:"
	echo "    MQResumeSendingTool -d origCatalog -f origFileName -m    "
	echo "Mandatory arguments:"
	echo "<origCatalog>     :the original catalog to be set."
	echo "Available:"
	echo "<origFileName>     :the original FileNmae is available. default is to sent all files of the catalog."
	echo "<MQconFile>      :the original MQconFile is available. default is automaticed readed from the MQResumeSending.cfg" 															}
}

# get -p parameter from MQResumeSending.cfg
function getParameter
{
	param1=`cat MQResumeSending.cfg | grep mq_resume_send_num | awk -F= '{print $2}'`
	param2=`cat MQResumeSending.cfg | grep mq_resume_send_pertime | awk -F= '{print $2}'`
	param3=`cat MQResumeSending.cfg | grep mq_resume_send_error_max | awk -F= '{print $2}'`
	param4=`cat MQResumeSending.cfg | grep mq_resume_send_record_num | awk -F= '{print $2}'`
	parameter="$param1|$param2|$param3|$param4"
}

# Not set JAVA_HOME exit
if [ -z "$JAVA_HOME" ]
then
    echo "JAVA_HOME not set, please set it and try again"
    exit 1
fi

# java cmd
if [ "x$JAVA" = "x" ]; then
    JAVA="$JAVA_HOME/bin/java"
fi


# iterate the input parameter  
sum=1
for line in $*
    do
        let "sum=$sum + 1"
        
        if [ "$line" = "-d" ]; then
            origCatalog=${!sum}
        fi  
        
        if [ "$line" = "-f" ]; then
            origFileName=${!sum} 
        fi  

		if [ "$line" = "-m" ]; then
            MQconFile=${!sum}
        fi 	
    done
	
# split joint command
if [ ! -n "$origCatalog" ]; then
	show_help
    exit 1
else
	params="$origCatalog"
	if [ ! -n "$origFileName" ]; then
		params="${params}"
		if [ ! -n "$MQconFile" ]; then
						MQconFile=`cat MQResumeSending.cfg | grep mq_conf_file | awk -F= '{print $2}'`
						if [ ! -n "$MQconFile" ]; then			
							getParameter
							params="${params} -p $parameter"        							
						else
							params="${params} -m $MQconFile"
							getParameter
							params="${params} -p $parameter"        							
						fi
        else
                        params="${params} -m $MQconFile"
                        getParameter
                        params="${params} -p $parameter"
		fi
	else 
		params="${params} -f $origFileName"
		if [ ! -n "$MQconFile" ]; then
						MQconFile=`cat MQResumeSending.cfg | grep mq_conf_file | awk -F= '{print $2}'`
						if [ ! -n "$MQconFile" ]; then						
							getParameter
							params="${params} -p $parameter"        							
						else
							params="${params} -m $MQconFile"
							getParameter
							params="${params} -p $parameter"        							
						fi
		else
						params="${params} -m $MQconFile"
						getParameter
						params="${params} -p $parameter"			
		fi
	fi
fi


# lib home
COMP_HOME=`cat MQResumeSending.cfg | grep mq_lib_path | awk -F= '{print $2}'`
APPLIB="$COMP_HOME"

APP_CLASSPATH="`find "$APPLIB" -name "*.jar" | sed 's/$/:/g'`"

for k in $APP_CLASSPATH;
   do TEMP_CLASSPATH=$k"$TEMP_CLASSPATH";
done
CONF_HOME=`cat MQResumeSending.cfg | grep mq_conf_file | awk -F= '{print $2}'`
APP_CLASSPATH=$TEMP_CLASSPATH:$CONF_HOME		
# Setup sepecific properties
JAVA_OPTS=" \
           -server \
           -Xms1024m \
           -Xmx2048m \
           -Xmn128m \
           -XX:+DisableExplicitGC \
           -XX:+UseConcMarkSweepGC \
           -XX:+UseParNewGC \
           -XX:PermSize=64m \
           -XX:MaxPermSize=128m \
           -XX:MinHeapFreeRatio=40 \
           -XX:MaxHeapFreeRatio=70 \
           -XX:CMSInitiatingOccupancyFraction=65 \
           -Dsun.rmi.dgc.server.gcInterval=0x7FFFFFFFFFFFFFE \
           -Dsun.rmi.dgc.client.gcInterval=0x7FFFFFFFFFFFFFE"

JAVA_OPTS="-Djava.security.egd=file:///dev/urandom $JAVA_OPTS"
#DEBUG_OPTS="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,address=58787,suspend=y"
#JAVA_OPTS="$JAVA_OPTS $DEBUG_OPTS"

#run_gclog=run_gc_`date +%Y%m%d%H%M%S`.log
#JAVA_OPTS="$JAVA_OPTS -Xverbosegclog:$run_gclog,10,40000"

# generate heap dump file when core dump
#JAVA_OPTS="$JAVA_OPTS -Xdump:heap"

# Setup log4j


"$JAVA" $JAVA_OPTS -classpath "$APP_CLASSPATH" com.huawei.jaguar.commons.mqresume.resendtool.MQResumeSendingTool -d $params 
