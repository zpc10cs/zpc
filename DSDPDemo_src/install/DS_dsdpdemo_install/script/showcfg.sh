#!/bin/sh 
# ****************************************************************************
#                                                                            *
#  monitor.sh: This is for Jaguar Platform                                   *
#                                                                            *
#  Copyright by Huawei Tech. Co., Ltd.                                       *
#  All rights reserved                                                       *
#                                                                            *
# ****************************************************************************

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

# lib home
APPLIB="$COMP_HOME"

APP_CLASSPATH="`find "$APPLIB" -name "*.jar" | sed 's/$/:/g'`"

for k in $APP_CLASSPATH;
   do TEMP_CLASSPATH=$k"$TEMP_CLASSPATH";
done
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

"$JAVA" $JAVA_OPTS -classpath "$APP_CLASSPATH" com.huawei.jaguar.commons.sdk.configuration.show.ShowConfig "$@" 

