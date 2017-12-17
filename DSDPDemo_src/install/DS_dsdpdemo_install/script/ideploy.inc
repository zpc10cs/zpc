#!/usr/bin/ksh
set +x
#############################################################################################
#FileName:ideploy.inc                                                                       #
#Author:weiyigang 00106702                                                                  #
#CreateDate:2007-03-30                                                                      #
#############################################################################################
#ʹ��˵��:                                                                                  #
#1.ideploy.inc�ļ�����Ʒ���ο����ű�����,���comm_lib�ļ��ļ���,�Լ�ideployȫ�ֱ����Ķ���   #
#2.Ϊ�����Ʒ����,����������汾���������ο����ű������޸ĵĹ�����,���Ʒ���ڶ��ο���ʱ��   #
#  ��ʹ�����еĶ��⹫����ȫ�ֱ�����ȡ���·��                                               #
#----------------------------------ȫ�ֱ����б�---------------------------------------------#
#1.IDEPLOY_PKG_PATH     Ŀ����������ο�������ҵ������������·��                            #
#2.IDEPLOY_CONFIG_DIR   Ŀ�������������ļ�����·��                                          #
#3.IDEPLOY_CONFIG       �����ļ�����                                                        #
#          ע���ű���ʹ��·��ʱ�����ʹ������ȫ�ֱ����е�·���Լ�������Щȫ�ֱ��������·�� #
#              ���ϱ�����ִ�ж��ο������ַ�����ʱ׷�ӵ�ideploy.inc�ļ���������ɺ�����Ч  #
#4.RETURN[0]            ȫ�ַ���ֵ,comm_lib��read_value������ȡ�ı���ֵ��ͨ���ñ�������     #
#############################################################################################
#if [ `echo "$0" |grep -c "/" ` -gt 0 ];then
#    cd ${0%/*}
#fi

#����ǰ·�����ӵ�����������
PATH=.:$PATH
export PATH

#����һ��iDeployר�õ������ļ�
IDEPLOY_NULL="$HOME/.ideploy_null"

#��������������
program_dir=`dirname $0`
#�ȼ���Ƿ������ű�ͬ��Ŀ¼��comm_lib,���������û���������ǰ·����
if [ -f ${program_dir}/comm_lib ];then
    . ${program_dir}/comm_lib
else
    . ./comm_lib
fi

#����汾�ų���
IDEPLOY_VERSION="Breeze iDeploy V100R001C04B37 @ [2008-12-09]"

#���巵��ֵ
RETURN[0]=""
RETURN[1]=""
RETURN[2]=""
RETURN[3]=""
RETURN[4]=""
RETURN[5]=""

#����ϵͳ����
OS_TYPE=""

#�����
typeset OS=`uname`
case ${OS} in
HP-UX)
    GREP="/usr/bin/grep"
    AWK="/usr/bin/awk"
    SED="/usr/bin/sed"
    DF="/usr/bin/bdf"
    OS_TYPE="hp"
;;
SunOS)
    AWK="/usr/xpg4/bin/awk"
    GREP="/usr/xpg4/bin/grep"
    SED="/usr/xpg4/bin/sed"
    DF="/usr/xpg4/bin/df"
    OS_TYPE="sun"
;;
Linux)
    GREP="/bin/grep"
    AWK="/bin/awk"
    SED="/bin/sed"
    DF="/bin/df"
    OS_TYPE="linux"
;;
AIX)
    GREP="/usr/bin/grep"
    AWK="/usr/bin/awk"
    SED="/usr/bin/sed"
    DF="/usr/bin/df"
    OS_TYPE="aix"
;;
*)
    GREP="/usr/bin/grep"
    AWK="/usr/bin/awk"
    SED="/usr/bin/sed" 
    DF="/usr/bin/df"
;;
esac

PING="ping"
find_path_dir="/usr/sbin /usr /bin /etc"

#��־����
if [ 2 -eq 1 ];then
    FAILED="\033[31mFAILED\033[0m"
    SUCCESSFUL="\033[32mSUCCESSFUL\033[0m"
    OK="\033[32mOK\033[0m"
    START="\033[35mSTART\033[0m"
    INFO="\033[32mINFO\033[0m"
    WARN="\033[33mWARN\033[0m"
    ERROR="\033[31mERROR\033[0m"
    WRONG="WRONG"
else
    FAILED="FAILED"
    SUCCESSFUL="SUCCESSFUL"
    OK="OK"
    START="START"
    INFO="INFO"
    WARN="WARN"
    ERROR="ERROR"
    WRONG="WRONG"
fi

EXEC_START="execute ${START}"
EXEC_FAIL="execute ${FAILED}"
EXEC_SUCC="execute ${OK}"
PARAMETER_UNMATCHED="Parameter(s) unmatched"

IS_NOT_A_FILE="is not a file, or not existence"
IS_NOT_A_DIR="is not a directory, or not existence"

#��ǰĿ¼
CUR_PATH=`pwd`

#���ο�������Ŀ¼
PKG_PATH=`cd ${CUR_PATH}/..;pwd`

#�ű�·��
SCRIPT_DIR="${PKG_PATH}/script"

#�����ļ�·��
CONFIG_DIR="${PKG_PATH}/conf"

#�����ļ�����
if [ -d ${CONFIG_DIR} ];then
    CONFIG=`ls ${CONFIG_DIR}|$GREP -i .properties$`
else
    CONFIG=""
fi

#B342CP0002ǰʹ�õ�����ǰ׺��ȫ�ֱ�����Ϊ��֤�Ѿ�ʹ�õĲ�Ʒ�ű��ļ����Խ��б���
#����������ȫ�ֱ���ͳһ����IDEPLOYǰ׺������Ͳ�Ʒ�Զ����ȫ�ֱ�����ͻ
IDEPLOY_CONFIG_DIR=${CONFIG_DIR}
IDEPLOY_PKG_PATH=${PKG_PATH}
IDEPLOY_CONFIG=${CONFIG}

#��ʱ�ļ�
TEMP="./.temp"

#ideploy_ftp/properties�ļ��е�������
IDEPLOY_DIR="ideploy_dir"
IDEPLOY_FTP="_ideploy_ftp"
IDEPLOY_FTP_FILE="_ideploy_ftp_files"
PKG_FTP="_pkg_ftp"
PKG_FTP_FILE="_pkg_ftp_files"
DISPATCH_FTP="_dispatch_ftp"
DISPATCH_FTP_FILE="_dispatch_ftp_files"

#��¼��Ҫ����İ���С
TOTAL_FILE_SIZE=0
#�ļ�����ĳ���ʱ��
TRANS_DURATION=0
#FILTER_WORDS="SUCCESSFUL successful Successful WARNING warning Warning ERROR error Error WARN warn Warn SUCCESS success Success FAILURE failure Failure FAILED failed Failed FAIL fail Fail"

#���ӵ�������־ǰ��,��ҳ����ɫʹ��
IDEPLOY_LOG_PREFIX="{:}{::}"
IDEPLOY_LOG_SUFFIX="{::}{:}"

#���ڱ�Ǻ���ҵ���ʹ��asciiģʽ����
IDEPLOY_ASCII="iDeploy_Ascii"

#�޸ĺ��IP��ȡ����
IP_OBTAIN_POLICY="static"

#BEGIN:������ĳ���
IDEPLOY_TMP_PATH="${CUR_PATH}"
RETNUM=0			# ���������Ԫ�ظ���
g_tmp_count=0

#mkdir -p ${IDEPLOY_TMP_PATH}
#chmod 777 ${IDEPLOY_TMP_PATH}

#�������
# ע:200���ϵĴ��������������ϵͳ�����������,����ʹ��
#
#������������������:
#   ERR_����ģ����_��������
#����:
#cfg_file.inc
#ERR_CFG_FILE_NOT_EXIST=1		#�ļ�������
#
#ע��:
#   1.����shell����ʹ�ó���255������Ϊ������,����ÿ��inc�ļ��Ĵ�����붼��1��ʼ.
#   2.ע��,ÿ�������Ķ������������Ӧ���ǲ�ͬ��,����ͬ����֮��ķ���ֵ������ͬ,
#   3.ͬһ��inc�ļ��µĲ�ͬ�����Ĵ������֮����ÿ��зָ���.���������ʵ�ע��˵��������
#   4.Ϊ��֤ÿ�������Ľӿ�����ȷ��,��Ҫֱ�ӷ����ڲ����õĺ����ķ���ֵ,��Ӧ�ò�������,
#     ������ת��Ϊ�Լ��ķ���ֵ.����:
#     cfg_file.inc�е�����file.inc�еĺ���:
#     file.inc�еĺ��������� ERR_FILE_NOT_EXIST, ��ʱ
#     cfg_file.inc�еĺ���Ӧ���� ERR_CFG_FILE_NOT_EXIST, ����Ҫֱ�ӷ���file.inc �ĺ����ķ���ֵ.




#common
#OK=0					# �ɹ�
ERROR=255   			# ʧ��
TRUE=0					# �����жϳɹ�
FLASE=1					# �����ж�ʧ��
ASSERT_ERROR=200    	# ����assert����,���³����˳����˳���
ERR_ABSTRACT_FUNC=254	# �������ӿڣ���Ҫ�ڸ�����ϵͳ��ʵ�ֵĺ���
PARA_ERROR=253			# ��������
YES=0														#yes
NO=1														#no
SUCC=0                    									#ִ�гɹ�
FAILURE=1
#FAILED=1
FAIL=1

# file.inc
ERR_PARAM_IS_NULL=2            #����Ϊ��
ERR_FILE_NOT_EXIST=3           #�ļ�������
ERR_FILE_ALREADY_EXIST=4       #�ļ��Ѵ���
ERR_FILE_CLEAR_FAIL=5          #����ļ�ʧ��
ERR_FILE_GET_LINES_ERROR=6     #��ȡ�ļ��кŴ���
ERR_FILE_LINENO_TOO_GREAT=7    #�ļ��к�̫��
ERR_FILE_CP_RM_SRC=8           #�����ļ�ʧ��
ERR_FILE_SED_PRINT=9           #sed��ӡʧ��
ERR_GET_LINE_NO=10             #��ȡ�ļ��к�ʧ��
ERR_APPEND_LINE_FAIL=11        #���ļ�ĩβ����һ�д���
ERR_FILE_GET_OWNER_FAIL=12     #��ȡ�ļ�����ʧ��
ERR_FILE_MKDIR_FAIL=13         #����Ŀ¼ʧ��
ERR_FILE_DELETE_FAIL=14        #�����ļ�ʧ��
ERR_CP_DIR_FAIL=15             #�����ļ�ʧ��
ERR_FILE_GET_GROUP_FAIL=16     #��ȡ�ļ�����Ⱥʧ��
ERR_FILE_CHG_OWNER_FAIL=17     #�ı��ļ�����ʧ��
ERR_FILE_GET_SIZE_FAIL=18      #��ȡ�ļ���Сʧ��
ERR_FILE_CP_FAIL=19            #�ļ�����ʧ��
ERR_EXPR_ERROR=20              #����ʧ��
ERR_FILE_CREAT=21			   #�����ļ�ʧ��
ERR_FILE_WRITE=22			   #д���ļ�ʧ��
ERR_FILE_CAT_FAIL=23		   #��ʾ�ļ�����ʧ��
ERR_DIR_NOT_EXIST=24           #Ŀ¼������
ERR_DIR_ALREADY_EXIST=25       #Ŀ¼�Ѵ���
ERR_DIR_DELETE_FAIL=26         #Ŀ¼ʧ��

# cfg_file.inc
ERR_CFG_FILE_NOT_EXIST=1		#�ļ�������
ERR_CFG_FILE_SEC_NOT_EXIST=3	#�β�����
ERR_CFG_FILE_KEY_NOT_EXIST=4	#��������

ERR_CFG_FILE_SEC_DUPLICATE=5	#���ظ�
ERR_CFG_FILE_KEY_DUPLICATE=6	#���ظ�


############### cfg_file.inc specify error return code #############

		## cfg common error return code : 1-10
ERR_CFG_PARA_ERROR=1					##������������
ERR_CFG_FILE_NOT_EXIST=2				##�ļ�������
ERR_CFG_FILE_GET_SEC_KEY_VALUE=3		# ��ȡ�����ļ��еļ�ֵʧ��
ERR_CFG_FILE_WRITE_SEC_KEY=4			# д�������ļ��м���ֵʧ��
ERR_CFG_FILE_KEY_NOT_ARRAY_TYPE=5		# ��(�ַ���)���������ʽ��




		##### special error return code :11-199
ERR_CFG_SEC_NOT_EXIST=11				##�β�����
ERR_CFG_SEC_ALREADY_EXIST=12			##���Ѿ�������
ERR_CFG_SEC_KEY_NOT_EXIST=13			##���еļ�������	
ERR_CFG_SEC_KEY_ALREADY_EXIST=14		##���еļ��Ѿ�����
ERR_CFG_INC_KEY_NOT_EXIST=15			##inc�ļ����еļ�������
ERR_CFG_INC_KEY_ALREADY_EXIST=16		##inc�ļ��еļ��Ѿ�����
ERR_CFG_RC_KEY_NOT_EXIST=17				##cshrc�ļ��еļ�������

#�޸�IP�Ĵ�����
#modify_eth_card_ip�����Ĵ�����
ERR_MOD_IP_NOT_LINUX=30              #����linux����ϵͳ
ERR_MOD_IP_NOT_ROOT=31               #����root�û�
ERR_MOD_IP_GET_ETH_NAME=32           #��ȡ��������ʧ�� 
ERR_MOD_IP_GET_ETH_CFG_FILE=33       #��ȡ���������ļ�ʧ�� 
ERR_MOD_IP_GET_CURR_IP=34            #ʹ��ifconfig��ȡ������ǰIPʧ��
ERR_MOD_IP_GET_CFG_CURR_IP=35        #�����������ļ���ȡ��ǰIPʧ��
ERR_MOD_IP_MOD_HOSTS_IP=36           #�޸�/etc/hosts�е�IPʧ��
ERR_MOD_IP_MOD_CFG_IP=37             #�޸����������ļ��е�IPʧ��
ERR_MOD_IP_MOD_CFG_NETMASK=38        #�޸���������ʧ��
ERR_MOD_IP_PARA_ERROR=39             #�޸�IP��������
ERR_MOD_IP_OBTAIN_POLICY=56          #�޸�������IP��ȡ����ʧ��
ERR_MOD_IP_IP_IS_USED=60             #�µ�IP�Ѿ�����������ʹ��  
ERR_MOD_IP_GET_OLD_BOND=62           #��ȡ������Ӧ�İ�����ʧ��

#modify_eth_card_netmask�����Ĵ�����
ERR_MOD_NETMASK_GET_CURR=40          #��ȡ��ǰ����������ʧ��
ERR_MOD_NETMASK_FAIL=41              #�޸����������ļ�����������ʧ��

#modify_eth_card_bond�����Ĵ�����
ERR_ETH_BOND_NOT_LINUX=42            #����Linux����ϵͳ
ERR_ETH_BOND_NOT_ROOT=43             #����root�û�
ERR_ETH_BOND_PARA_ERROR=44           #��������ȷ
ERR_ETH_BOND_GET_ETH_NAME=45         #��ȡ��������ʧ��
ERR_ETH_BOND_GET_ETH_CFG_FILE=46     #��ȡ���������ļ�ʧ��
ERR_ETH_BOND_GET_OLD_BOND=47         #��ȡ�����ϵİ�����ʧ��
ERR_ETH_BOND_RESTART_NETWORK=48      #�����󶨣���������ʧ�� 
ERR_ETH_BOND_FILE_NOT_EXIST=49       #�������ļ�û������
ERR_ETH_BOND_FAIL=50                 #������ʧ��
ERR_ETH_BOND_IP_IS_USED=61           #�󶨵�IP����������ʹ��

#get_eth_name_by_alias�����Ĵ�����
ERR_GET_ETH_NAME_NOT_LINUX=51        #����Linux����ϵͳ
ERR_GET_ETH_NAME_PARA_ERROR=52       #��������ȷ
ERR_ETH_ALIAS_SCRIPT_NOT_EXIST=53    #��ȡ����������������Ӧ��ϵ�Ľű�eth_alias.sh������
ERR_ETH_NAME_NOT_UNIQUE=54           #����������ƥ����������Ʋ�Ψһ
ERR_ETH_NAME_NOT_EXIST=55            #����������Ӧ���������Ʋ�����

#modify_hostip_obtain_policy����������
ERR_MOD_IP_OBTAIN_POLICY_PARA_ERR=57          #��������ȷ
ERR_MOD_IP_OBTAIN_POLICY_GET_CURR=58          #��ȡ������ǰ��IP��ȡ����ʧ��
ERR_MOD_IP_OBTAIN_POLICY_MOD_CONFIG_FILE=59   #�޸����������ļ��е�IP��ȡ����ʧ��

#END:������ĳ���


