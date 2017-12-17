#!/usr/bin/ksh

function get_ipinfo_from_compname
{
		typeset compName=$1
		#read compinfo.cfg
		awk -F\# '{print $1}' "$APP_HOME/compinfo.cfg" |
		sed '/^[    ]*$/d' |
		sed -n "/^[     ]*\[[   ]*$compName[  ]*\]/,/^[       ]*\[.*\]/p" |
		sed '/^[        ]*\[.*\]/d' > $tempFileName

		serverip=$(cat $tempFileName | grep admintooladrr | awk -F= '{print $2}'| awk -F: '{print $1}')
		serverport=$(cat $tempFileName | grep admintooladrr | awk -F= '{print $2}'| awk -F: '{print $2}')
		
		rm $tempFileName
		return 0
}

# check IP valid
function CheckIPAddr
{
	ipaddr=$1
    echo $ipaddr|grep "^[0-9]\{1,3\}\.\([0-9]\{1,3\}\.\)\{2\}[0-9]\{1,3\}$" > /dev/null;
	if [ $? -ne 0 ]
	then
		echo "IP must be all num"
		return 1
	fi
	a=`echo $ipaddr|awk -F . '{print $1}'`  #spilt by '.', get the column 
	b=`echo $ipaddr|awk -F . '{print $2}'`
	c=`echo $ipaddr|awk -F . '{print $3}'`
	d=`echo $ipaddr|awk -F . '{print $4}'`

	for num in $a $b $c $d
	do
		if [ $num -gt 255 ] || [ $num -lt 0 ];then
			return 1
		fi
	done
	return 0
}

function show_help
{	
	echo "Usage:  logview <logType> <-s [10.10.10.10:]8080 | [-m upm]>  	"					                                                  	
	echo "Example:                                                         	"					                                                  	
	echo "		logview all -m upm												"																			
	echo "Or:																"																			
	echo "		logview debug -s 192.168.1.1:8080						"																			
	echo "Mandatory arguments:                                             	"					                                                  	
	echo "    <logtype>        :Log type to be set,ignoring the case.      	"					                                                                    	
	echo "                      Available:ALL|DEBUG|RUN|INTERFACE|RUNTIME|SECURITY|OPERATION|STATE|TRACELINK                 					"		
	echo "                      \"ALL\" for all log type.                 	"					                                                  	
	echo "OPTIONS:                                                         	"					                                                  	
	echo "    -s    the server service address.                         	"					                                          	
	echo "    -m    module name.                 			            	"					                                                  	
	echo "                                                                 	"							                                                  	
}

if [ $# -ne 3 ];then
	show_help
	exit 1
fi

#Example:
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

#dirname $PWD

# shell file path
APP_HOME=$(cd "$(dirname "$0")"; pwd)

#comp home
typeset APP_HOME=$(cd "$(dirname "$0")"; pwd)

# lib home
APPLIB="$APP_HOME/tools"

# app dependency jars
#APP_CLASSPATH=$(find "$APPLIB" -name "*.jar" ) 
APP_CLASSPATH="`find "$APPLIB" -name "*.jar" | sed 's/$/:/g'`"

#transfor arry to string
for k in $APP_CLASSPATH;
   do TEMP_CLASSPATH=$k"$TEMP_CLASSPATH";
done

APP_CLASSPATH=$TEMP_CLASSPATH


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


typeset tempFileName=tmp_file_`date +%s`.bak
typeset logType=""
typeset serverip=""
typeset serverport=""
typeset modulename=""

typeset args_num=$#
typeset i=1
while [ $i -le ${args_num} ]
do
	eval args[${i}]='$'$i
	((i=i+1))
done
typeset logType=${args[1]}
if [ $args_num -eq 3 ] ;then
	if [ ${args[2]} = "-s" ];then
		serverip=$(echo ${args[3]} | awk -F: '{print $1}')
		serverport=$(echo ${args[3]} | awk -F: '{print $2}')
	elif [ ${args[2]} = "-m" ];then
		modulename="${args[3]}"
	else
		show_help
		exit 1
	fi
else
	show_help
	exit 1
fi

if [ "X${modulename}" != "X" ];then
	get_ipinfo_from_compname "${modulename}"
	if [ $? -ne 0 ];then
		echo "init module ip and port failed."
	fi	
fi

if [ "X${serverip}" != "X" ];then
	CheckIPAddr "${serverip}"
	if [ $? -ne 0 ];then
		echo "invoke function CheckIPAddr failed."
	fi
fi


"$JAVA" $JAVA_OPTS -classpath "$APP_CLASSPATH" com.huawei.jaguar.commons.logview.SendLogViewMessage "$logType" "$serverip" "$serverport"




