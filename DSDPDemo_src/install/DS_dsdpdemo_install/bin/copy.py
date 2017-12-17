import os
import re
import javapath as path
from com.huawei.breeze.ideploy.online import OnlineNEInfoUtil
from com.huawei.breeze.ideploy.config import OnlineConfigUtil
from com.huawei.breeze.ideploy.config import OnlineHostUtil
from com.huawei.breeze.ideploy.config import OnlineConfigException
from com.huawei.breeze.ideploy.config import OnlineConfigLog
from com.huawei.breeze.ideploy.online import OnlinePKGUtil
from ideploypublic import *
from public import *
from java.io import File
from java.lang import String

_result = []

def copy():
    files=File(_currentPKGPath + "/../../onesdp_common_pkg")
    if files.exists():
        for filename in files.list():
            fileWriteStreamObject = open(_currentPKGPath + "/../apppkg/" + filename, "wb")
            fileReadStreamObject = open(_currentPKGPath + "/../../onesdp_common_pkg/" + filename, "rb")
            try:
                fileWriteStreamObject.write(fileReadStreamObject.read())
            finally:
                fileWriteStreamObject.close()
                fileReadStreamObject.close()
    else:
        _result.append("empty_pkg_error")
def main():
    print "temp string"
    #copy()

##################################main function#############################################################
main()