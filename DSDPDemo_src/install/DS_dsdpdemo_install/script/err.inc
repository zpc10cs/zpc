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
OK=0					# �ɹ�
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
FAILED=1
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

# cluster.inc ����Ŵ� 100-120
ERR_CLU_GET_VER=100					#��ȡ˫���汾��Ϣʧ��
ERR_CLU_NO_TRUST=101				#˫��û�����ι�ϵ

# types.inc ����Ŵ� 121-140
ERR_TYP_NOT_NONNEGATIVE=121				#���ǷǸ���������
ERR_TYP_NONNEGATIVE=122					#�ǷǸ���������
ERR_TYP_OVER_FLOW=123					#�����������
ERR_TYP_NEGATIVE=124					#����
ERR_TYP_POSITIVE=125					#����
ERR_TYP_NOT_INTEGER=126					#��������

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

# �˶����Ҫ����ɺ�c����ʵ�ֵĳ����еĴ�����һ�£���Ϊshell�ű���ֱ�ӷ�����c�ķ���ֵ
ERR_XML_FAIL=1					#�ļ������ڵȴ���
ERR_XML_PARSERERR=2				#����ʧ��
ERR_XML_NOTFOUNDNODE=3			#û���ҵ���Ӧ�Ľڵ�
ERR_XML_NOTFOUNDATT=4			#δ��������ֵ
ERR_XML_NOSUPPORTENCODINGBAD=5	#��֧�ֵ��ַ������߱���
ERR_XML_ALREDYEXIST=6			#�Ѿ��ýڵ��������


############## user.inc specify error return code

ERR_USER_USER_NOT_EXIST=8               #�û�������
ERR_USER_GROUP_NOT_EXIST=2              #�鲻����
ERR_USER_USER_EXIST=3                   #�û��Ѵ���
ERR_USER_USER_ID_EXIST=7                #�û�ID�Ѵ���
ERR_USER_GROUP_EXIST=5 		        #���Ѵ���
ERR_USER_GROUP_ID_EXIST=6		#��id�Ѵ���
ERR_USER_HOMEDIR_IS_SYSDIR=4		#HOME·����ϵͳĿ¼
ERR_USER_SHELL_NOT_EXIST=9          #SHELL������
ERR_USER_USE_EXIST_USER=10          #�û��Ѿ������Ҵ����ɹ�
ERR_USER_USE_EXIST_GROUP=11         #���Ѿ������Ҵ����ɹ�

############## str.inc specify error return code


############## para.inc specify error return code

## para common error return code : 1 - 10
ERR_PARA_ERROR=1			##����Ĳ�������
ERR_PARA_NOT_INITIAL=2		##Ҫ�����Ĳ���û�г�ʼ��,����û��set������ȡĳ��������ֵ
ERR_PARA_OPT_NOT_SET=3		##ĳ��opt����û������


############## os.inc specify error return code ##########################
ERR_UNSUPPORT_PLATFORM=3                                   #ƽ̨��֧��
ERR_MAP_HOST_FILE_DONOT_EXIST=4                            #host�ļ�������
ERR_MAP_HOST_FILE_IS_EMPTY=5                             #hosts�ļ��ǿյ�
ERR_GET_IP_BY_HOSTNAME_MAPPING_HOSTS_FAILED=77              #ӳ��hosts�ļ�ʧ��
ERR_GET_IP_BY_HOSTNAME_NOT_FOUND=8                         #û���ҵ�IP
ERR_GET_HOSTNAME_BY_IP_MAPPING_HOSTS_FAILED=10             #ӳ��hosts�ļ�ʧ��
ERR_GET_HOSTNAME_BY_IP_NOT_FOUND=11                         #û���ҵ�hostname
ERR_ADD_HOSTS_RECORD_MAPPING_HOSTS_FAILED=13               #ӳ��hosts�ļ�ʧ��
ERR_ADD_HOSTS_RECORD_BY_IP_NAME_IP_EXIST=14                #�����ӵ�IP����
ERR_ADD_HOSTS_RECORD_BY_IP_NAME_ADDING_FAILED=15           #���Ӽ�¼��hosts�ļ�ʧ��
ERR_DEL_HOSTS_RECORD_BY_IP_NOT_EXIST=17                    #��ɾ����IP������
ERR_DEL_HOSTS_RECORD_BY_IP_DELETEING_FAILED=18             #ɾ��hosts�ļ��еļ�¼ʧ��
ERR_GET_USERNAME_BY_USERID_NOT_EXIST=20                    #userID������
ERR_GET_USERHOME_BY_USERID_NOT_EXIST=21                    #userID������
ERR_GET_USERHOME_BY_USERNAME_NOT_EXIST=22                  #�û�������
ERR_TO_GET_SPACE_USED_RATIO_BY_CMD_DF=25                   #��SUN�µ���ϵͳ����DF��ȡ�ռ�ʧ��
ERR_TO_GET_FREE_SPACE_BY_CMD_DF=26                         #��SUN�µ���ϵͳ����DF��ȡ�ռ�ʧ��
ERR_TO_GET_FREE_SPACE_BY_CMD_AWK=27                        #����AWKת����λ��ȡ�ռ�ʧ��
ERR_GET_MOUNT_POINT_DIR_NOT_EXIST=28                       #Ŀ¼������
ERR_ADD_VFSTAB_REC_PARAMSNUM_ERROR=29                      #���ݵĲ�����������
ERR_ADD_VFSTAB_REC_PARAM_EMPTY=30                          #����Ϊ���ַ�������
ERR_ADD_VFSTAB_REC_KEYWORD_EXIST=31                        #�ؼ����ظ�����������
ERR_ADD_VFSTAB_REC_ADD_RECORD_FAILED=32                    #���Ӽ�¼ʧ��
ERR_DEL_VFSTAB_REC_PARAMSNUM_ERROR=33                      #������������
ERR_DEL_VFSTAB_REC_CANNOT_FIND_KEYWORD_IN_VFSTAB_FILE=34   #û���ҵ�ƥ��Ĺؼ���
ERR_DEL_VFSTAB_REC_DEL_RECORD_BY_KEYWORD_FAILED=35         #���ݹؼ���ɾ����¼ʧ��
ERR_IS_DISK_MIRROR_GET_VG_FAILED=36                        #��ȡLVʧ��
ERR_GET_CFG_OS_VER_FAILED=37                               #��ȡ�����ļ���OS�汾����

ERR_OS_NONCONNECT=90		#���Ӳ�ͨ

