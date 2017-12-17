import    os
import    javapath    as    path
from    com.huawei.breeze.ideploy.online    import    OnlineNEInfoUtil
from    com.huawei.breeze.ideploy.online    import    OnlineSystemUtil
from    com.huawei.breeze.ideploy.config    import    OnlineConfigUtil
from    com.huawei.breeze.ideploy.config    import    OnlineHostUtil
from    com.huawei.breeze.ideploy.config    import    OnlineConfigException
from    com.huawei.breeze.ideploy.util    import    TerminalFactory
from    com.huawei.breeze.ideploy.util    import    TerminalPY
from    public    import    *
from    ideploypublic    import    *
import    re

_result    =    []
#_sid    is    a    global    variable,    it    is    a    session    id    which    is    provide    by    iDeploy
host_util    =    OnlineHostUtil    (_sid,    1)
config_util    =    OnlineConfigUtil(_sid)
neinfo_util    =    OnlineNEInfoUtil(_sid)

#����û����������õ��û�������ͬ
def    checkUserNameIsSameForUserConfig():
    allUserNameList = []
    allUserHomeList = []
    if config_util.containConfigItem("appuser_compment_ref"):
        configSetNum = config_util.getConfigSetIndexs("appuser_compment_ref")
        index = 0
        while index < configSetNum:
            username = config_util.getValue("user_name",index,0)
            userHome = config_util.getValue("user_home",index,0)
            allUserNameList.append(username)
            allUserHomeList.append(userHome)
            index += 1
    if config_util.containConfigItem("zookeeper_user_name"):
        allUserNameList.append(config_util.getValue("zookeeper_user_name"))
        allUserHomeList.append(config_util.getValue("zookeeper_user_home"))
    if config_util.containConfigItem("redis_user_name"):    
        allUserNameList.append(config_util.getValue("redis_user_name"))
        allUserHomeList.append(config_util.getValue("redis_user_home"))
    if config_util.containConfigItem("persisredis_user_name"):  
        allUserNameList.append(config_util.getValue("persisredis_user_name"))
        allUserHomeList.append(config_util.getValue("persisredis_user_home"))
    if config_util.containConfigItem("lc_user_name"):
        allUserNameList.append(config_util.getValue("lc_user_name"))
        allUserHomeList.append(config_util.getValue("lc_user_home"))
    for userName in allUserNameList:
        if allUserNameList.count(userName) > 1:
            errorString = "The username for different ne can not same,same user: " + userName
            if errorString not in _result:
                _result.append(errorString)
    for userhome in allUserHomeList:
        if allUserHomeList.count(userhome) > 1:
            errorString = "The userhome path for different ne can not same,same userhome path: " + userhome
            if errorString not in _result:
                _result.append(errorString)            
                
#����û����������е�Ӧ��������뱻ѡ��
def checkAllHaveBeSelectedForUserConfig():
    if not config_util.containConfigItem("appuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("appuser_compment_ref")
    allSelectedAppCompmentList = []
    index = 0
    while index < configSetNum:
        compment = config_util.getValue("appuser_compment_ref",index,0)
        for item in compment.split(","):
            allSelectedAppCompmentList.append(item)
        index += 1
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    allDynamicUserCompmentList = getAllAppCompment().split(",")
    allShouldSelectCompmentList = getCommonItemBetweenList(currentTaskSelectNeTypeList,allDynamicUserCompmentList)

    for ne in allShouldSelectCompmentList.split(","):
        if ne not in allSelectedAppCompmentList:
            errorString = "The ne's username have not been configured,ne is: " + ne
            if errorString not in _result:
                _result.append(errorString)

#����û�������ͬһ����Ԫ���ܱ�ѡ����
def checkSameNeIsSelectedOnceForUserConfig():
    if not config_util.containConfigItem("appuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("appuser_compment_ref")
    allSelectedAppNe = []
    index = 0
    while index < configSetNum:
        nes = config_util.getValue("appuser_compment_ref",index,0)
        for ne in nes.split(","):
            allSelectedAppNe.append(ne)
        index += 1 
    for item in allSelectedAppNe:
        if allSelectedAppNe.count(item) > 1:
            errorString = "For user configuration,the ne: "+ item + " should not been selected more than once"
            if errorString not in _result:
                _result.append(errorString)
 
#���Oracle������Ϣ������ͬһ����Ԫ���ܱ�ѡ���� 
def checkSameNeIsSelectedOnceForOracleConfig():
    if not config_util.containConfigItem("dbuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("dbuser_compment_ref")
    allSelectedAppNe = []
    index = 0
    while index < configSetNum:
        nes = config_util.getValue("dbuser_compment_ref",index,0)
        for ne in nes.split(","):
            allSelectedAppNe.append(ne)
        index += 1
    for item in allSelectedAppNe:
        if allSelectedAppNe.count(item) > 1:
            errorString = "For oracle configuration,the ne: "+ item + " should not been selected more than once"
            if errorString not in _result:
                _result.append(errorString)

#���Oracle�������������е�Ӧ��������뱻ѡ��
def checkAllHaveBeSelectedForOracleConfig():
    if not config_util.containConfigItem("dbuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("dbuser_compment_ref")
    allSelectedAppCompmentList = []
    index = 0
    while index < configSetNum:
        compment = config_util.getValue("dbuser_compment_ref",index,0)
        for item in compment.split(","):
            allSelectedAppCompmentList.append(item)
        index += 1
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    allOracleCompment = getAllConnectOracleCompment()
    allOracleCompmentString = getCommonItemBetweenList(currentTaskSelectNeTypeList,allOracleCompment)    
    for ne in allOracleCompmentString.split(","):
        if ne not in allSelectedAppCompmentList:
            errorString = "The ne's oracle connection info have not been configured,ne is: " + ne
            if errorString not in _result:
                _result.append(errorString)            

#���Oracle�������������õ�Oracle IP������ͬ
def    checkUserNameIsSameForOracleConfig():
    if not config_util.containConfigItem("dbuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("dbuser_compment_ref")
    allOracleIPList = []
    index = 0
    while index < configSetNum:
        oracleType = config_util.getValue("oracle_server_type",index,0)
        if oracleType != 'RAC':
            oracleIp = config_util.getValue("oracle_server_ip",index,0)
            allOracleIPList.append(oracleIp)
        index += 1
    for item in allOracleIPList:
        if allOracleIPList.count(item) > 1:
            errorString = "The oracle connection info can not be same,same oracle ip is: " + item
            if errorString not in _result:
                _result.append(errorString)

#�����ˢ���ݿ��������oracle��װ��ʽ����ΪRAC����ܲ�֧��oracle��rac��װ��ʽ��ˢ�⣩
def checkOracleInstallType():
    if not config_util.containConfigItem("dbuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("dbuser_compment_ref")
    index = 0
    while index < configSetNum:
        oracleType = config_util.getValue("oracle_server_type",index,0)
        if oracleType == 'RAC':
            errorString = "When is_need_db is 'YES', oracle_server_type must be No-RAC.Please check it."
            if errorString not in _result:
                _result.append(errorString)
        index += 1

def main():
    isNeedDB  = config_util.getValue("is_need_db")
    checkSameNeIsSelectedOnceForUserConfig()
    #checkAllHaveBeSelectedForUserConfig()
    checkUserNameIsSameForUserConfig()    
    checkSameNeIsSelectedOnceForOracleConfig()
    checkAllHaveBeSelectedForOracleConfig()
    checkUserNameIsSameForOracleConfig()
    if isNeedDB == 'YES':        
        checkOracleInstallType()
#####################################main#######################################
main()


