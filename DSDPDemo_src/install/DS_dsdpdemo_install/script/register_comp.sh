typeset file=${HOME}/bin/compinfo.cfg
if [ $# -ne 1 ];then
	echo "ERROR" "Parameters count of register_comp error."
	exit 1
fi
typeset tmp_file=$1
dos2unix ${tmp_file}
typeset line_tmp=$(cat $tmp_file | head -n 1| awk -F[ '{print $2}' | awk -F] '{print $1}')

grep "\[$line_tmp\]" ${file} > /dev/null
if [ $? -ne 0 ];then
	cat ${tmp_file} >> ${file}
	echo "" >> ${file}
else
	echo "comp: $line_tmp has already been registed."
fi
