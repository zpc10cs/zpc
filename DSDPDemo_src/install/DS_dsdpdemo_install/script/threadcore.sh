#!/bin/sh 
# ****************************************************************************
#                                                                            *
#  monitor.sh: This is for Jaguar Platform                                   *
#                                                                            *
#  Copyright by Huawei Tech. Co., Ltd.                                       *
#  All rights reserved                                                       *
#                                                                            *
# *****************************************************************************

# Not set JAVA_HOME exit

CORE_LOG_FILE=threadcore.log

if [ -z "$JAVA_HOME" ]
then
    echo "JAVA_HOME not set, please set it and try again" >> $CORE_LOG_FILE
    exit 1
fi

# jstack cmd
if [ "x$jstack" = "x" ]; then
    JSTACK="$JAVA_HOME/bin/jstack"
fi

# jmap cmd
if [ "x$jmap" = "x" ]; then
    JMAP="$JAVA_HOME/bin/jmap"
fi



#dirname $PWD

TMP_PATH=$(cd "$(dirname "$0")"; pwd)
export APP_HOME=`dirname ${TMP_PATH}`
echo $APP_HOME
CUR_USER=`whoami`
APP_PID=`ps -fu ${CUR_USER} |grep java |grep ${APP_HOME}|awk -F ' ' '{print $2}'`


if [ "x$APP_PID" != "x" ]; then
	CORE_FILE=javacore_`date +%Y%m%d%H%M%S`.log
	HEAP_FILE=heapdump_`date +%Y%m%d%H%M%S`.hprof
	
    mkdir -p $APP_HOME/bin/javacore
    PSTAT=`ps aux | grep ${APP_PID} | grep -v "grep" | awk -F " " '{print $8}'`  
    PSTAT=${PSTAT:0:1}
    if [ "${PSTAT}x" != "Tx" -a "${PSTAT}x" != "Zx" ]; then
      "$JSTACK" -F $APP_PID > $APP_HOME/bin/javacore/$CORE_FILE	
    else
      gstack  $APP_PID > $APP_HOME/bin/javacore/$CORE_FILE	
    fi
    if [ ! -d $APP_HOME/bin/heapdump ];then
    mkdir -p $APP_HOME/bin/heapdump
    fi
jmap -dump:format=b,file=$APP_HOME/bin/heapdump/$HEAP_FILE $APP_PID
fi
