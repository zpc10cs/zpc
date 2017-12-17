#!/usr/bin/ksh

. $HOME/bin/shelllib/ideploy.inc
. $HOME/bin/shelllib/logutil.lib
. $HOME/bin/shelllib/commonfunc.lib
. $HOME/bin/shelllib/comm_lib


typeset alias_name="$1"
typeset comp_name="$2"

typeset filename=$HOME/bin/compinfo.cfg


cfg_get_sec_key_value ${filename} "${comp_name}" "${alias_name}"
if [ $? -ne 0 ]; then
	echo "fail to get startapp command of ${component_name}"
	exit 1
fi

typeset dir_command="${RETURN[0]}"

cd $HOME/${dir_command}

