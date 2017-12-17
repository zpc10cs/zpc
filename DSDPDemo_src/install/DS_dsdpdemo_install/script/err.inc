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
OK=0					# 成功
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
FAILED=1
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

# cluster.inc 错误号从 100-120
ERR_CLU_GET_VER=100					#获取双机版本信息失败
ERR_CLU_NO_TRUST=101				#双机没有信任关系

# types.inc 错误号从 121-140
ERR_TYP_NOT_NONNEGATIVE=121				#不是非负整型数据
ERR_TYP_NONNEGATIVE=122					#是非负整型数据
ERR_TYP_OVER_FLOW=123					#数据类型溢出
ERR_TYP_NEGATIVE=124					#负数
ERR_TYP_POSITIVE=125					#正数
ERR_TYP_NOT_INTEGER=126					#不是整数

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

# 此定义必要定义成和c语言实现的程序中的错误定义一致，因为shell脚本中直接返回了c的返回值
ERR_XML_FAIL=1					#文件不存在等错误
ERR_XML_PARSERERR=2				#解析失败
ERR_XML_NOTFOUNDNODE=3			#没有找到相应的节点
ERR_XML_NOTFOUNDATT=4			#未找着属性值
ERR_XML_NOSUPPORTENCODINGBAD=5	#不支持的字符集或者编码
ERR_XML_ALREDYEXIST=6			#已经该节点或者属性


############## user.inc specify error return code

ERR_USER_USER_NOT_EXIST=8               #用户不存在
ERR_USER_GROUP_NOT_EXIST=2              #组不存在
ERR_USER_USER_EXIST=3                   #用户已存在
ERR_USER_USER_ID_EXIST=7                #用户ID已存在
ERR_USER_GROUP_EXIST=5 		        #组已存在
ERR_USER_GROUP_ID_EXIST=6		#组id已存在
ERR_USER_HOMEDIR_IS_SYSDIR=4		#HOME路径是系统目录
ERR_USER_SHELL_NOT_EXIST=9          #SHELL不存在
ERR_USER_USE_EXIST_USER=10          #用户已经存在且创建成功
ERR_USER_USE_EXIST_GROUP=11         #组已经成在且创建成功

############## str.inc specify error return code


############## para.inc specify error return code

## para common error return code : 1 - 10
ERR_PARA_ERROR=1			##传入的参数错误
ERR_PARA_NOT_INITIAL=2		##要处理的参数没有初始化,比如没有set就立即取某个参数的值
ERR_PARA_OPT_NOT_SET=3		##某个opt参数没有设置


############## os.inc specify error return code ##########################
ERR_UNSUPPORT_PLATFORM=3                                   #平台不支持
ERR_MAP_HOST_FILE_DONOT_EXIST=4                            #host文件不存在
ERR_MAP_HOST_FILE_IS_EMPTY=5                             #hosts文件是空的
ERR_GET_IP_BY_HOSTNAME_MAPPING_HOSTS_FAILED=77              #映射hosts文件失败
ERR_GET_IP_BY_HOSTNAME_NOT_FOUND=8                         #没有找到IP
ERR_GET_HOSTNAME_BY_IP_MAPPING_HOSTS_FAILED=10             #映射hosts文件失败
ERR_GET_HOSTNAME_BY_IP_NOT_FOUND=11                         #没有找到hostname
ERR_ADD_HOSTS_RECORD_MAPPING_HOSTS_FAILED=13               #映射hosts文件失败
ERR_ADD_HOSTS_RECORD_BY_IP_NAME_IP_EXIST=14                #待添加的IP存在
ERR_ADD_HOSTS_RECORD_BY_IP_NAME_ADDING_FAILED=15           #添加记录到hosts文件失败
ERR_DEL_HOSTS_RECORD_BY_IP_NOT_EXIST=17                    #待删除的IP不存在
ERR_DEL_HOSTS_RECORD_BY_IP_DELETEING_FAILED=18             #删除hosts文件中的记录失败
ERR_GET_USERNAME_BY_USERID_NOT_EXIST=20                    #userID不存在
ERR_GET_USERHOME_BY_USERID_NOT_EXIST=21                    #userID不存在
ERR_GET_USERHOME_BY_USERNAME_NOT_EXIST=22                  #用户不存在
ERR_TO_GET_SPACE_USED_RATIO_BY_CMD_DF=25                   #在SUN下调用系统命令DF获取空间失败
ERR_TO_GET_FREE_SPACE_BY_CMD_DF=26                         #在SUN下调用系统命令DF获取空间失败
ERR_TO_GET_FREE_SPACE_BY_CMD_AWK=27                        #调用AWK转换单位获取空间失败
ERR_GET_MOUNT_POINT_DIR_NOT_EXIST=28                       #目录不存在
ERR_ADD_VFSTAB_REC_PARAMSNUM_ERROR=29                      #传递的参数个数错误
ERR_ADD_VFSTAB_REC_PARAM_EMPTY=30                          #参数为空字符串错误
ERR_ADD_VFSTAB_REC_KEYWORD_EXIST=31                        #关键字重复，不能添加
ERR_ADD_VFSTAB_REC_ADD_RECORD_FAILED=32                    #添加记录失败
ERR_DEL_VFSTAB_REC_PARAMSNUM_ERROR=33                      #参数个数错误
ERR_DEL_VFSTAB_REC_CANNOT_FIND_KEYWORD_IN_VFSTAB_FILE=34   #没有找到匹配的关键字
ERR_DEL_VFSTAB_REC_DEL_RECORD_BY_KEYWORD_FAILED=35         #根据关键字删除记录失败
ERR_IS_DISK_MIRROR_GET_VG_FAILED=36                        #获取LV失败
ERR_GET_CFG_OS_VER_FAILED=37                               #获取配置文件中OS版本错误

ERR_OS_NONCONNECT=90		#连接不通


