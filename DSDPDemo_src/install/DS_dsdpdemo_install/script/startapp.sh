. $HOME/bin/shelllib/ideploy.inc
. $HOME/bin/shelllib/logutil.lib
. $HOME/bin/shelllib/commonfunc.lib
. $HOME/bin/shelllib/comm_lib

typeset component_name="$1"
if [ $# -eq 0 ];then
	component_name="all"
fi


typeset filename=$HOME/bin/compinfo.cfg
typeset tmpname=$HOME/bin/start.tmp
if [ "X$component_name" = "Xall" ];then
	cat ${filename} | grep "\[*\]" | while read line
	do
		typeset tmp_comp_name=`echo $line|sed "s/\[//g"|sed "s/\]//g"`
		if [ "X${tmp_comp_name}" = "Xuniagent" ];then
			continue
		fi
		cfg_get_sec_key_value ${filename} "${tmp_comp_name}" "startapp"
		if [ $? -ne 0 ]; then
			echo "fail to get startapp command of ${component_name}"
			exit 1
		fi
	
		typeset start_command="${RETURN[0]}"
		$HOME/${start_command}
	done
	cfg_get_sec_key_value ${filename} "uniagent" "startapp"
	if [ $? -ne 0 ]; then
		echo "fail to get startapp command of uniagent"
		exit 1
	fi
	start_agent="${RETURN[0]}"
	$HOME/${start_agent}
	exit 0
fi


cfg_get_sec_key_value ${filename} "${component_name}" "startapp"
if [ $? -ne 0 ]; then
	echo "fail to get startapp command of ${component_name}"
	exit 1
fi

typeset start_command="${RETURN[0]}"


$HOME/${start_command}
