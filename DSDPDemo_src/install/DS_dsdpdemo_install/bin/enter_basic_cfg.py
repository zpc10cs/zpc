#when use the refresh function of iDeploy,set some config item unedit.
import os
import javapath as path
from com.huawei.breeze.ideploy.online import OnlineNEInfoUtil
from com.huawei.breeze.ideploy.config import OnlineConfigUtil
from com.huawei.breeze.ideploy.config import OnlineHostUtil
from com.huawei.breeze.ideploy.config import OnlineConfigException
from com.huawei.breeze.ideploy.util import TerminalFactory
from com.huawei.breeze.ideploy.util import TerminalPY
from public import *
from ideploypublic import *
import    re
import user_info

#_sid is a global variable, it is a session id which is provide by iDeploy.
host_util    =    OnlineHostUtil    (_sid,    1)
config_util = OnlineConfigUtil(_sid)
neinfo_util = OnlineNEInfoUtil(_sid)

ne_info_dict = {}

#get the absoltepath of config file, initialize it as common_file
#_currentPKGPath is a global variable, it means the current path of this script.
current_ne_list = neinfo_util.getAttributeValue('_selectedNETypeList').split(',')
DEBUGRUNLOG(current_ne_list)
for tmp_ne in current_ne_list:
    ne_info_dict[tmp_ne] =  NEInformation(_sid, tmp_ne)


#获取当然任务中选中的所有网元，并保存在隐藏配置项中    
def getCurrentTaskNeTypeList():
    hostList = host_util.getHostIDList()
    currTaskNetypeString = None
    for hostID in hostList:
        CurrHostNeType =  neinfo_util.getNeTypeListByHostId(hostID)
        for tmpNeType in CurrHostNeType:
            if None == currTaskNetypeString:
                currTaskNetypeString = tmpNeType
            elif tmpNeType not in currTaskNetypeString.split(","):
                currTaskNetypeString = currTaskNetypeString + "," + tmpNeType
    config_util.setValue("_currentTaskNeTypeList",currTaskNetypeString)

   
#设置页面用户配置的默认展示    
def adjustUserConfigDisplay():
    if not config_util.containConfigItem("appuser_compment_ref"):
        return
    #先清理掉所有的动态配置集，只保留一个
    configSetNum = config_util.getConfigSetIndexs("appuser_compment_ref")
    index = 1
    while index < configSetNum:
        config_util.removeConfigSet("user_config",1)
        index+=1
    #config_util.clearCheckboxConfigItemValue("appuser_compment_ref",0,0)
    #动态添加可选网元
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    allDynamicUserCompment = getAllAppCompment()
    #for ne in currentTaskSelectNeTypeList:
        #if ne in allDynamicUserCompment.split(","):
            #config_util.addCheckboxConfigItemValue("appuser_compment_ref",0,0,ne)
    #添加动态配置项集        
    configSetIndex = 0    
    for key in user_info.default_user_config_dic.keys():
        selectNeString = None
        for ne in user_info.default_user_config_dic[key].split(":")[0].split(","):
            if ne in currentTaskSelectNeTypeList:
                #config_util.addCheckboxConfigItemValue("appuser_compment_ref",0,0,ne)
                selectNeString = None == selectNeString and ne or selectNeString + "," + ne
        if None != selectNeString:
            if configSetIndex >= 1:
                config_util.addConfigSet("user_config",configSetIndex - 1)            
            config_util.setValue("appuser_compment_ref",configSetIndex,0,selectNeString)
            configSetIndex += 1

#设置Oracle数据库的默认展示            
def adjustOracleConfigDisplay():
    if not config_util.containConfigItem("dbuser_compment_ref"):
        return
    configSetNum = config_util.getConfigSetIndexs("dbuser_compment_ref")
    index = 1
    while index < configSetNum:
        config_util.removeConfigSet("oracle_info",1)
        index+=1
    #config_util.clearCheckboxConfigItemValue("dbuser_compment_ref",0,0)
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    allOracleCompment = getAllConnectOracleCompment()
    allOracleCompmentString = getCommonItemBetweenList(currentTaskSelectNeTypeList,allOracleCompment)
    #for ne in allOracleCompmentString.split(","):          
        #config_util.addCheckboxConfigItemValue("dbuser_compment_ref",0,0,ne)
    config_util.setValue("dbuser_compment_ref",0,0,allOracleCompmentString)        
 
#设置zookeeper,redis的IP的配置展示
def adjustZookeeperIpConfigDisplay():
    #zookeeper IP的展示
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    if "ZooKeeper" in currentTaskSelectNeTypeList:
        config_util.displayConfig("zookeeper_service_ip",0,0,False)
        allZookeeperIPs = None
        for zookeeperNe in neinfo_util.getNEInfoByType("ZooKeeper"):
            if None == allZookeeperIPs:
                allZookeeperIPs = ("" == zookeeperNe.getServiceIp() and zookeeperNe.getAddress() or zookeeperNe.getServiceIp())
            else:
                allZookeeperIPs = allZookeeperIPs + "," + ("" == zookeeperNe.getServiceIp() and zookeeperNe.getAddress() or zookeeperNe.getServiceIp())           
        config_util.setValue("zookeeper_service_ip",allZookeeperIPs)
    else:
        if config_util.containConfigItem("zookeeper_service_ip"):
            config_util.displayConfig("zookeeper_service_ip",0,0,True) 
            
#设置所有UPM和SNS节点的IP到隐藏配置项中，供后台使用            
def setUPMAndSNSAllServiceIP():
    allUPMIPs = None
    allSNSIPs = None
    allMQIPs = None
    currentTaskSelectNeTypeList = config_util.getValue("_currentTaskNeTypeList").split(',')
    if "UPM" in currentTaskSelectNeTypeList:
        for upmNe in neinfo_util.getNEInfoByType("UPM"):
            if None == allUPMIPs:
                allUPMIPs = ("" == upmNe.getServiceIp() and upmNe.getAddress() or upmNe.getServiceIp())
            else:
                allUPMIPs = allUPMIPs + "," + ("" == upmNe.getServiceIp() and upmNe.getAddress() )           
        config_util.setValue("upm_service_ip_all",allUPMIPs)
    
    if "SNS" in currentTaskSelectNeTypeList:
        for snsNe in neinfo_util.getNEInfoByType("SNS"):
            if None == allSNSIPs:
                allSNSIPs = ("" == snsNe.getServiceIp() and snsNe.getAddress() or snsNe.getServiceIp())
            else:
                allSNSIPs = allSNSIPs + "," + ("" == snsNe.getServiceIp() and snsNe.getAddress() )           
        config_util.setValue("sns_service_ip_all",allSNSIPs)
    if "MQ" in currentTaskSelectNeTypeList:
        for mqNe in neinfo_util.getNEInfoByType("MQ"):
            if None == allMQIPs:
                allMQIPs = ("" == mqNe.getServiceIp() and mqNe.getAddress() or mqNe.getServiceIp())
            else:
                allMQIPs = allMQIPs + "," + ("" == mqNe.getServiceIp() and mqNe.getAddress() )           
        config_util.setValue("mq_ip_list",allMQIPs)

        
def app_db_SelectOrNot():
    ne_list = ""
    flag = "no"
    dbflag = "no"
    
    for NeTYPT in neinfo_util.getAttributeValue('_selectedNETypeList').split(','):
        ip_list=ne_info_dict[NeTYPT].getIpList()
        if len(ip_list) > 0 :
            ne_list = NeTYPT + "," + ne_list
    config_util.setValue("_selectedNETypeList2",ne_list)    
    for comp in ['TAG','UPM','CHARGING','ORDER','PRODUCT','SUBSCRIPTION','CGW','PLMF','CONTENT','PAYMENT','SNS','publicinfo','CAMPAIGN','MARKETINGMGMT','CHANNELMGMT','DSDPDEMO'] :
        for selected_comp in ne_list.split(','):
            if selected_comp != "" and  selected_comp == comp :
                flag = "yes"
                break;
    for db_comp in ['UPM','SNS','CHARGING','ORDER','PRODUCT','SUBSCRIPTION','CGW','CONTENT','PAYMENT','publicinfo','CAMPAIGN','MARKETINGMGMT','CHANNELMGMT','DSDPDEMO'] :
        for selected_comp in ne_list.split(','):
            if selected_comp != "" and  selected_comp == db_comp :
                dbflag = "yes"
                break;

    config_util.setValue("isAppSelected",flag)
    config_util.setValue("isDBAppSelected",dbflag)    

def comp_to_create_sysdb():
    comp = "null"
    for NeTYPT in config_util.getValue("_selectedNETypeList2").split(','):
        for comp in ['UPM','SNS','CGW','PAYMENT'] :
            if comp == NeTYPT :
                config_util.setValue("comp_create_sysdb",comp)
                break;
                
def comp_to_create_chgdb():
    comp = "null"
    for NeTYPT in config_util.getValue("_selectedNETypeList2").split(','):
        for comp in ['CHARGING','CAMPAIGN'] :
            if comp == NeTYPT :
                config_util.setValue("comp_create_chgdb",comp)
                break;
        
def    setLocalNEList():
    machinc_list    =    ""
    all_ip    =    []
    for    tmp_ne    in    current_ne_list:
        all_ip.extend(ne_info_dict[tmp_ne].getActualIpList())
    local_ip_list    =    uniqueList(all_ip)
    
    for    tmp_ip    in    local_ip_list:
        local_list    =    ''
        for    ne    in    current_ne_list:
            if    tmp_ip    in    ne_info_dict[ne].getActualIpList():
                if    local_list    ==    '':
                    local_list    =    ne
                else:
                    local_list    =    local_list    +    "/"    +    ne
        if    machinc_list    ==    "":
            machinc_list    =    tmp_ip    +    ":"    +    local_list
        else:
            machinc_list    =    machinc_list    +    ","    +    tmp_ip    +    ":"    +    local_list
    
    config_util.setValue("_localMachineNEList",    machinc_list)

def main():
    getCurrentTaskNeTypeList()
    if _taskOperateType == "new_create_task":
        adjustUserConfigDisplay()
        adjustOracleConfigDisplay()
    adjustZookeeperIpConfigDisplay()
    #setUPMAndSNSAllServiceIP()
    app_db_SelectOrNot()
    comp_to_create_sysdb()
    #comp_to_create_chgdb()
    setLocalNEList()
###############################################main#################################################
main()

