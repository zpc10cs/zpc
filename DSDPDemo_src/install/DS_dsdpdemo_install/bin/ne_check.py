import os
import javapath as path
from com.huawei.breeze.ideploy.online import OnlineNEInfoUtil
from com.huawei.breeze.ideploy.config import OnlineConfigUtil
from com.huawei.breeze.ideploy.config import OnlineHostUtil
from com.huawei.breeze.ideploy.config import OnlineConfigException
from com.huawei.breeze.ideploy.config import OnlineConfigLog
from com.huawei.breeze.ideploy.online import OnlinePKGUtil
from ideploypublic import *
from public import *

_result = []
host_util = OnlineHostUtil (_sid, 1)
config_util = OnlineConfigUtil(_sid)
neinfo_util = OnlineNEInfoUtil(_sid)
pkg_util = OnlinePKGUtil(_sid)

################################################################################
# Function    : checkMachineType
# Description :	check machine type has same one
# parameter list:null
# Output      : None
# Return      : 1 failure
#               0 success
################################################################################
def checkNeSelectedHosts():
    currTaskNetTypeList = []
    hostList = host_util.getHostIDList()
    for hostID in hostList:
        CurrHostNeType =  neinfo_util.getNeTypeListByHostId(hostID)
        for tmpNeType in CurrHostNeType:
            if tmpNeType not in currTaskNetTypeList:
                currTaskNetTypeList.append(tmpNeType)
    for ne in currTaskNetTypeList:
        neinfoList = neinfo_util.getNEInfoByType(ne)
        for neinfo in neinfoList:
            for item in neinfoList:
                if neinfo.getHostId() != item.getHostId() and neinfo.getAddress() == item.getAddress():
                    errorString = "The ne: " + ne +" should not select the same address host,same address is: " + neinfo.getAddress()
                    if errorString not in _result:
                        _result.append(errorString)
            
def main():
    #暂时先不校验
    pkg_util.validatePKG(1)
    checkNeSelectedHosts()

##################################main function#############################################################
main()



