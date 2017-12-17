. $HOME/bin/shelllib/ideploy.inc
. $HOME/bin/shelllib/logutil.lib
. $HOME/bin/shelllib/commonfunc.lib
. $HOME/bin/shelllib/comm_lib

typeset component_name="$1"
typeset filename=$HOME/bin/compinfo.cfg

if [ "X$component_name" = "Xall" ];then
	while read line
	do
		echo $line | grep "statusapp"  1>/dev/null 2>&1 
		if [ $? -eq 0 ];then 
			typeset command=$(echo ${line} | awk -F= '{print $2}' )
			if [ "X${command}" != "X" ];then
				$HOME/${command}
			fi
		fi
	done < ${filename}
	exit 0
fi


cfg_get_sec_key_value ${filename} "${component_name}" "statusapp"
if [ $? -ne 0 ]; then
	echo "fail to get statusapp command of ${component_name}"
	exit 1
fi

typeset statusapp_command="${RETURN[0]}"


$HOME/${statusapp_command}

