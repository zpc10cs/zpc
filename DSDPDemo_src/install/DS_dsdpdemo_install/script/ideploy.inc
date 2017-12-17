#!/usr/bin/ksh
set +x
#############################################################################################
#FileName:ideploy.inc                                                                       #
#Author:weiyigang 00106702                                                                  #
#CreateDate:2007-03-30                                                                      #
#############################################################################################
#使用说明:                                                                                  #
#1.ideploy.inc文件供产品二次开发脚本调用,完成comm_lib文件的加载,以及ideploy全局变量的定义   #
#2.为方便产品开发,及避免后续版本升级给二次开发脚本带来修改的工作量,请产品侧在二次开发时务   #
#  必使用已有的对外公开的全局变量获取相关路径                                               #
#----------------------------------全局变量列表---------------------------------------------#
#1.IDEPLOY_PKG_PATH     目标主机侧二次开发包及业务软件包所在路径                            #
#2.IDEPLOY_CONFIG_DIR   目标主机侧配置文件所在路径                                          #
#3.IDEPLOY_CONFIG       配置文件名称                                                        #
#          注：脚本中使用路径时请务必使用上述全局变量中的路径以及基于这些全局变量的相对路径 #
#              以上变量在执行二次开发包分发步骤时追加到ideploy.inc文件，步骤完成后方能生效  #
#4.RETURN[0]            全局返回值,comm_lib中read_value函数读取的变量值即通过该变量返回     #
#############################################################################################
#if [ `echo "$0" |grep -c "/" ` -gt 0 ];then
#    cd ${0%/*}
#fi

#将当前路径添加到环境变量中
PATH=.:$PATH
export PATH

#定义一个iDeploy专用的垃圾文件
IDEPLOY_NULL="$HOME/.ideploy_null"

#包含公共函数库
program_dir=`dirname $0`
#先检查是否存在与脚本同级目录的comm_lib,有则包含，没有则包含当前路径下
if [ -f ${program_dir}/comm_lib ];then
    . ${program_dir}/comm_lib
else
    . ./comm_lib
fi

#定义版本号常量
IDEPLOY_VERSION="Breeze iDeploy V100R001C04B37 @ [2008-12-09]"

#定义返回值
RETURN[0]=""
RETURN[1]=""
RETURN[2]=""
RETURN[3]=""
RETURN[4]=""
RETURN[5]=""

#操作系统类型
OS_TYPE=""

#命令常量
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

#日志常量
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

#当前目录
CUR_PATH=`pwd`

#二次开发包的目录
PKG_PATH=`cd ${CUR_PATH}/..;pwd`

#脚本路径
SCRIPT_DIR="${PKG_PATH}/script"

#配置文件路径
CONFIG_DIR="${PKG_PATH}/conf"

#配置文件名称
if [ -d ${CONFIG_DIR} ];then
    CONFIG=`ls ${CONFIG_DIR}|$GREP -i .properties$`
else
    CONFIG=""
fi

#B342CP0002前使用的是无前缀的全局变量，为保证已经使用的产品脚本的兼容性进行保留
#后续公开的全局变量统一带有IDEPLOY前缀，避免和产品自定义的全局变量冲突
IDEPLOY_CONFIG_DIR=${CONFIG_DIR}
IDEPLOY_PKG_PATH=${PKG_PATH}
IDEPLOY_CONFIG=${CONFIG}

#临时文件
TEMP="./.temp"

#ideploy_ftp/properties文件中的配置项
IDEPLOY_DIR="ideploy_dir"
IDEPLOY_FTP="_ideploy_ftp"
IDEPLOY_FTP_FILE="_ideploy_ftp_files"
PKG_FTP="_pkg_ftp"
PKG_FTP_FILE="_pkg_ftp_files"
DISPATCH_FTP="_dispatch_ftp"
DISPATCH_FTP_FILE="_dispatch_ftp_files"

#记录需要传输的包大小
TOTAL_FILE_SIZE=0
#文件传输的持续时间
TRANS_DURATION=0
#FILTER_WORDS="SUCCESSFUL successful Successful WARNING warning Warning ERROR error Error WARN warn Warn SUCCESS success Success FAILURE failure Failure FAILED failed Failed FAIL fail Fail"

#添加到级别日志前后,供页面着色使用
IDEPLOY_LOG_PREFIX="{:}{::}"
IDEPLOY_LOG_SUFFIX="{::}{:}"

#用于标记后续业务包使用ascii模式传输
IDEPLOY_ASCII="iDeploy_Ascii"

#修改后的IP获取策略
IP_OBTAIN_POLICY="static"

#BEGIN:李博新增的常量
IDEPLOY_TMP_PATH="${CUR_PATH}"
RETNUM=0			# 返回数组的元素个数
g_tmp_count=0

#mkdir -p ${IDEPLOY_TMP_PATH}
#chmod 777 ${IDEPLOY_TMP_PATH}

#错误代码
# 注:200以上的错误代码属于属于系统保留错误代码,请勿使用
#
#错误代码变量命名规则:
#   ERR_函数模块名_错误描述
#例如:
#cfg_file.inc
#ERR_CFG_FILE_NOT_EXIST=1		#文件不存在
#
#注意:
#   1.由于shell不能使用超过255的数作为返回码,所以每个inc文件的错误代码都从1开始.
#   2.注意,每个函数的多个错误代码变量应该是不同的,而不同函数之间的返回值可以相同,
#   3.同一个inc文件下的不同函数的错误代码之间采用空行分隔开.可以添加适当注释说明函数名
#   4.为保证每个函数的接口是明确的,不要直接返回内部调用的函数的返回值,而应该捕获它们,
#     把它们转化为自己的返回值.例如:
#     cfg_file.inc中调用了file.inc中的函数:
#     file.inc中的函数返回了 ERR_FILE_NOT_EXIST, 此时
#     cfg_file.inc中的函数应返回 ERR_CFG_FILE_NOT_EXIST, 而不要直接返回file.inc 的函数的返回值.




#common
#OK=0					# 成功
ERROR=255   			# 失败
TRUE=0					# 条件判断成功
FLASE=1					# 条件判断失败
ASSERT_ERROR=200    	# 发生assert错误,导致程序退出的退出码
ERR_ABSTRACT_FUNC=254	# 抽象函数接口，需要在各操作系统层实现的函数
PARA_ERROR=253			# 参数不对
YES=0														#yes
NO=1														#no
SUCC=0                    									#执行成功
FAILURE=1
#FAILED=1
FAIL=1

# file.inc
ERR_PARAM_IS_NULL=2            #参数为空
ERR_FILE_NOT_EXIST=3           #文件不存在
ERR_FILE_ALREADY_EXIST=4       #文件已存在
ERR_FILE_CLEAR_FAIL=5          #清空文件失败
ERR_FILE_GET_LINES_ERROR=6     #获取文件行号错误
ERR_FILE_LINENO_TOO_GREAT=7    #文件行号太大
ERR_FILE_CP_RM_SRC=8           #撤除文件失败
ERR_FILE_SED_PRINT=9           #sed打印失败
ERR_GET_LINE_NO=10             #获取文件行号失败
ERR_APPEND_LINE_FAIL=11        #在文件末尾增加一行错误
ERR_FILE_GET_OWNER_FAIL=12     #获取文件属主失败
ERR_FILE_MKDIR_FAIL=13         #创建目录失败
ERR_FILE_DELETE_FAIL=14        #撤除文件失败
ERR_CP_DIR_FAIL=15             #拷贝文件失败
ERR_FILE_GET_GROUP_FAIL=16     #获取文件所属群失败
ERR_FILE_CHG_OWNER_FAIL=17     #改变文件属主失败
ERR_FILE_GET_SIZE_FAIL=18      #获取文件大小失败
ERR_FILE_CP_FAIL=19            #文件拷贝失败
ERR_EXPR_ERROR=20              #计算失败
ERR_FILE_CREAT=21			   #创建文件失败
ERR_FILE_WRITE=22			   #写入文件失败
ERR_FILE_CAT_FAIL=23		   #显示文件内容失败
ERR_DIR_NOT_EXIST=24           #目录不存在
ERR_DIR_ALREADY_EXIST=25       #目录已存在
ERR_DIR_DELETE_FAIL=26         #目录失败

# cfg_file.inc
ERR_CFG_FILE_NOT_EXIST=1		#文件不存在
ERR_CFG_FILE_SEC_NOT_EXIST=3	#段不存在
ERR_CFG_FILE_KEY_NOT_EXIST=4	#键不存在

ERR_CFG_FILE_SEC_DUPLICATE=5	#段重复
ERR_CFG_FILE_KEY_DUPLICATE=6	#键重复


############### cfg_file.inc specify error return code #############

		## cfg common error return code : 1-10
ERR_CFG_PARA_ERROR=1					##参数个数不对
ERR_CFG_FILE_NOT_EXIST=2				##文件不存在
ERR_CFG_FILE_GET_SEC_KEY_VALUE=3		# 读取配置文件中的键值失败
ERR_CFG_FILE_WRITE_SEC_KEY=4			# 写入配置文件中键和值失败
ERR_CFG_FILE_KEY_NOT_ARRAY_TYPE=5		# 键(字符串)不是数组格式的




		##### special error return code :11-199
ERR_CFG_SEC_NOT_EXIST=11				##段不存在
ERR_CFG_SEC_ALREADY_EXIST=12			##段已经存在了
ERR_CFG_SEC_KEY_NOT_EXIST=13			##段中的键不存在	
ERR_CFG_SEC_KEY_ALREADY_EXIST=14		##段中的键已经存在
ERR_CFG_INC_KEY_NOT_EXIST=15			##inc文件的中的键不存在
ERR_CFG_INC_KEY_ALREADY_EXIST=16		##inc文件中的键已经存在
ERR_CFG_RC_KEY_NOT_EXIST=17				##cshrc文件中的键不存在

#修改IP的错误码
#modify_eth_card_ip函数的错误码
ERR_MOD_IP_NOT_LINUX=30              #不是linux操作系统
ERR_MOD_IP_NOT_ROOT=31               #不是root用户
ERR_MOD_IP_GET_ETH_NAME=32           #获取网卡名称失败 
ERR_MOD_IP_GET_ETH_CFG_FILE=33       #获取网卡配置文件失败 
ERR_MOD_IP_GET_CURR_IP=34            #使用ifconfig获取网卡当前IP失败
ERR_MOD_IP_GET_CFG_CURR_IP=35        #从网卡配置文件获取当前IP失败
ERR_MOD_IP_MOD_HOSTS_IP=36           #修改/etc/hosts中的IP失败
ERR_MOD_IP_MOD_CFG_IP=37             #修改网卡配置文件中的IP失败
ERR_MOD_IP_MOD_CFG_NETMASK=38        #修改子网掩码失败
ERR_MOD_IP_PARA_ERROR=39             #修改IP参数错误
ERR_MOD_IP_OBTAIN_POLICY=56          #修改网卡的IP获取策略失败
ERR_MOD_IP_IP_IS_USED=60             #新的IP已经被其他网卡使用  
ERR_MOD_IP_GET_OLD_BOND=62           #获取网卡对应的绑定名称失败

#modify_eth_card_netmask函数的错误码
ERR_MOD_NETMASK_GET_CURR=40          #获取当前的子网掩码失败
ERR_MOD_NETMASK_FAIL=41              #修改网卡配置文件中子网掩码失败

#modify_eth_card_bond函数的错误码
ERR_ETH_BOND_NOT_LINUX=42            #不是Linux操作系统
ERR_ETH_BOND_NOT_ROOT=43             #不是root用户
ERR_ETH_BOND_PARA_ERROR=44           #参数不正确
ERR_ETH_BOND_GET_ETH_NAME=45         #获取网卡名称失败
ERR_ETH_BOND_GET_ETH_CFG_FILE=46     #获取网卡配置文件失败
ERR_ETH_BOND_GET_OLD_BOND=47         #获取网卡老的绑定名称失败
ERR_ETH_BOND_RESTART_NETWORK=48      #网卡绑定，重启网卡失败 
ERR_ETH_BOND_FILE_NOT_EXIST=49       #网卡绑定文件没有生成
ERR_ETH_BOND_FAIL=50                 #网卡绑定失败
ERR_ETH_BOND_IP_IS_USED=61           #绑定的IP被其他网卡使用

#get_eth_name_by_alias函数的错误码
ERR_GET_ETH_NAME_NOT_LINUX=51        #不是Linux操作系统
ERR_GET_ETH_NAME_PARA_ERROR=52       #参数不正确
ERR_ETH_ALIAS_SCRIPT_NOT_EXIST=53    #获取网卡别名和网卡对应关系的脚本eth_alias.sh不存在
ERR_ETH_NAME_NOT_UNIQUE=54           #与网卡别名匹配的网卡名称不唯一
ERR_ETH_NAME_NOT_EXIST=55            #网卡别名对应的网卡名称不存在

#modify_hostip_obtain_policy函数错误码
ERR_MOD_IP_OBTAIN_POLICY_PARA_ERR=57          #参数不正确
ERR_MOD_IP_OBTAIN_POLICY_GET_CURR=58          #获取网卡当前的IP获取策略失败
ERR_MOD_IP_OBTAIN_POLICY_MOD_CONFIG_FILE=59   #修改网卡配置文件中的IP获取策略失败

#END:李博新增的常量



