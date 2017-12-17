#!/usr/bin/ksh
#set -x
program_dir=`dirname $0`
cd ${program_dir}
. ${program_dir}/ideploy.inc
#########################################
#����:wrap
#����:��ɶ�ҵ��ű����õķ�װ
#����:
#########################################
#########################################################################################
#history:2007-05-23:Tag first label
#modify:A01E30851
#########################################################################################
function wrap
{
    #set -x
    typeset func_name="wrap"
    typeset ret=""
    #ִ��ҵ����õĽű���������
    $@
    ret=$?
    return ${ret}
    
}

#�����������NULL�ļ�
>${IDEPLOY_NULL}

typeset file_name="ideploy_wrap.sh"
typeset ret_value=""

if [ "X$1" = "X-v" ];then
    if [ "X${IDEPLOY_VERSION}" = "X" ];then
        echo "Can't get the ideploy version!"
        exit 1
    fi
    echo ${IDEPLOY_VERSION}
    exit 0
elif [ "X$1" = "Xlocal" ];then
    typeset command=$2
    if [ ! -f ${command} ];then
        return 1
    fi
    chmod +x ${command}
    #ִ��ָ��
    ${command}
    exit 0
else
    echo "command [ $@ ]"
    wrap $@
fi

#��¼ִ�еķ���ֵ
ret_value=$?

#ɾ��NULL�ļ�
rm -f ${IDEPLOY_NULL}

if [ ${ret_value} -ne 0 ];then
    #Begin:A01E30851,2007-05-22,weiyigang,Del the log
    #log_echo "log" "${file_name}" "Excute \"${file_name}\" ${FAILED}!"
    #End:A01E30851,2007-05-22,weiyigang
    echo "iDeploy:Error:FAILED"
    return 1
else
    #Begin:A01E30851,2007-05-22,weiyigang,Del the log
    #log_echo "log" "${file_name}" "Excute \"${file_name}\" ${SUCCESSFUL}!"
    #End:A01E30851,2007-05-22,weiyigang
    echo "iDeploy:End:SUCCESSFUL"
    return 0
fi


