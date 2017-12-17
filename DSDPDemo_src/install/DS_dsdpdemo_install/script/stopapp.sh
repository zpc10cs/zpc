. $HOME/bin/shelllib/ideploy.inc
. $HOME/bin/shelllib/logutil.lib
. $HOME/bin/shelllib/commonfunc.lib
. $HOME/bin/shelllib/comm_lib

typeset component_name="$1"
if [ $# -eq 0 ];then
	component_name="all"
fi
typeset filename=$HOME/bin/compinfo.cfg

if [ "X$component_name" = "Xall" ];then
	while read line
	do
		echo $line | grep "stopapp" 1>/dev/null 2>&1
		if [ $? -eq 0 ];then
			typeset command=$(echo ${line} | awk -F= '{print $2}' )  
			if [ "X${command}" != "X" ];then
				$HOME/${command}
			fi
		fi
	done < ${filename}
	exit 0
fi


cfg_get_sec_key_value ${filename} "${component_name}" "stopapp"
if [ $? -ne 0 ]; then
	echo "fail to get stopapp command of ${component_name}"
	exit 1
fi

typeset stop_command="${RETURN[0]}"


$HOME/${stop_command}

