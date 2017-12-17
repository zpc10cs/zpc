import os
import javapath as path
from time import localtime
from time import strftime
from com.huawei.breeze.ideploy.online import OnlineNEInfoUtil
from com.huawei.breeze.ideploy.config import OnlineConfigUtil
from com.huawei.breeze.ideploy.config import OnlineHostUtil
from com.huawei.breeze.ideploy.config import OnlineConfigException
from com.huawei.breeze.ideploy.config import OnlineConfigLog
from com.huawei.breeze.ideploy.util import TerminalFactory
from com.huawei.breeze.ideploy.util import TerminalPY

from public import *

#Ideploy Globe Variable Define
#using the three type 'MINI_TYPE' 'SMALL_TYPE' 'MIDILL_TYPE' 'PLAT_MINI_TYPE' 
#'PLAT_SMALL_TYPE' 'PLAT_MIDDLE_TYPE' to describe the netype
MDSP_IPTV_TYPE = 'up_small'

#Error Type
READ_VALUE_ERROR = "Reading value failed : "
MACHINE_TYPE_ERROR = "Machine type error : "
CLUSTER_ERROR = "Cluster error : "
CONSTRUCT_NET_ERROR = "Construct error : "

#File Name
KERNEL_CONFIG_FILE = {
	MDSP_IPTV_TYPE:'../script/'+MDSP_IPTV_TYPE+'.ini',
}

IP_PARAMETER_TRANSFER_CONFIG_FILE = {
	MDSP_IPTV_TYPE:'../script/'+MDSP_IPTV_TYPE+'.ini',
}

UOA_PARAMETER_TRANSFER_CONFIG_FILE='config.ini'

PARAMETER_ALL_CONFIGFILE = 'config_allinone.ini'

DISPLAY_CONFIG_SET_FALSE_FILE = 'display_config_set_false.ini'
DISPLAY_CONFIG_ITEM_FALSE_FILE = 'display_config_item_false.ini'

	
################################################################################
#FUNCTION NAME : getIpListByComm
#DESCRIBE	   : From the common_file_path, get the NE name which installed the compent
#                you selected by parameter comm_name. You should give the ne_info_dict
#                on the same time, the ne_info_dict is a dictonary which saved the NEInformation,
#                from ne_info_dict we can touch each NE's information. The function will return 
#                a Ip list, the list contain all NE's IP installed the compent. The IP list
#                makes up of dual host 's float ip and single's actual ip.
#PARAMETER IN  : _sid, common_file_path, ne_info_dict, comm_name
#PARAMETER OUT :
#RETURN VALUE  : com_all_ip_list, a ip list with dual host's float ip and single's actual ip.
################################################################################
def getIpListByComm(_sid, common_file_path, ne_info_dict, comm_name):
	neinfo_util = OnlineNEInfoUtil(_sid)
	com_all_ip_list = []
	for tmp_ne in interList(getNEFromComName(common_file_path, comm_name), neinfo_util.getAttributeValue('_selectedNETypeList').split(',')):
		com_all_ip_list.extend(ne_info_dict[tmp_ne].getIpList())
	return uniqueList(com_all_ip_list)

############################################################
#
#
##################################
def getIpListByNE(ne_name,ne_info_dict):
	#neinfo_util = OnlineNEInfoUtil(_sid)
	ne_all_ip_list = []

	ne_all_ip_list.extend(ne_info_dict[ne_name].getIpList())
	print "getIpListByNE"
	print ne_all_ip_list
	return uniqueList(ne_all_ip_list)
	
################################################################################
#FUNCTION NAME : getActualIpListByComm
#DESCRIBE	   : Same as function getIpListByComm, only the ip list makes up of 
#                each machine's actual ip list.
#PARAMETER IN  : _sid, common_file_path, ne_info_dict, comm_name
#PARAMETER OUT :
#RETURN VALUE  : com_all_actual_ip_list, a ip list with all machine's actual ip.
################################################################################
def getActualIpListByComm(_sid, common_file_path, ne_info_dict, comm_name):
	neinfo_util = OnlineNEInfoUtil(_sid)
	com_all_actual_ip_list  = []
	for tmp_ne in interList(getNEFromComName(common_file_path, comm_name), neinfo_util.getAttributeValue('_selectedNETypeList').split(',')):
		com_all_actual_ip_list.extend(ne_info_dict[tmp_ne].getActualIpList())
	return uniqueList(com_all_actual_ip_list)

################################################################################
#FUNCTION NAME : addAndSetVaule
#DESCRIBE	   : The config_id is public dynamic config id,can add and set, on the 
#                same time, the value_list is a list you set to the config_id. The 
#                function will automatic add the config_id's number to the length 
#                of the value_list, and set the value_list to the config_ids.
#PARAMETER IN  : _sid, config_id, value_list
#PARAMETER OUT :
#RETURN VALUE  : 
################################################################################
def addAndSetVaule(_sid, config_id, value_list):
	print value_list
	config_util = OnlineConfigUtil(_sid)
	length = len(value_list)
	if length == 0:
		RUNLOG('Some thing be error, the ne can not find one machine, Please check it!')
	else:
		while length > config_util.getConfigItemIndexs(config_id, 0):
			config_util.addConfigItem(config_id, 0, 0)
		while length < config_util.getConfigItemIndexs(config_id, 0):
			config_util.removeConfigItem(config_id, 0, 0)
		for x in range(len(value_list)):
			config_util.setValue(config_id, 0, x, value_list[x])
############################
#############################
def getNEFromPkgName(config_file_name, pkg_name):
	config_file = IniFile(config_file_name)
	print "getNEFromPkgName"
	for tmp_ne in config_file.getSectionValue('NE-COMPONENT-REF'):
		print tmp_ne
		tmp_ne_list = config_file.getSectionKeyValue('NE-COMPONENT-REF', tmp_ne).split(',')
		if tmp_ne_list.count(pkg_name) == 1:
			return tmp_ne

################################################################################
#FUNCTION NAME : getNEFromComName
#DESCRIBE	   : Give the config_file_name and com_name, the function will return
#                the NE list installed compent named com_name. The information is 
#                defined in the config file named config_file_name.
#PARAMETER IN  : config_file_name, com_name
#PARAMETER OUT :
#RETURN VALUE  : 
################################################################################
def getNEFromComName(config_file_name, com_name):
	#return_ne_list is used by saved all ne which installed com_name
	return_ne_list = []
	
	config_file = IniFile(config_file_name)
	if com_name.count('_') == 1:
		com_pkg_list = []
		pfx_sub_list = com_name.split('_')
		com_pfx_list = config_file.getSectionKeyValue('SUB-COMPONENT-PREFIX', pfx_sub_list[1]).split(',')
		for tmp_com_pfx in com_pfx_list:
			tmp_com_pfx_list = tmp_com_pfx.split('|')
			if tmp_com_pfx_list[1] == pfx_sub_list[0]:
				com_pkg_list.append(tmp_com_pfx_list[0])
				
		for tmp_ne in config_file.getSectionValue('NE-COMPONENT-REF'):
			tmp_ne_list = config_file.getSectionKeyValue('NE-COMPONENT-REF', tmp_ne).split(',')
			for com_pkg in com_pkg_list:
				if tmp_ne_list.count(com_pkg) == 1:
					return_ne_list.append(tmp_ne)
		
	else:
		com_pkg_list = []
		for tmp_com_pkg in config_file.getSectionValue('COMPONENT-REF'):
			tmp_com_list = config_file.getSectionKeyValue('COMPONENT-REF', tmp_com_pkg).split(',')
			if tmp_com_list.count(com_name) == 1:
				com_pkg_list.append(tmp_com_pkg)

		print com_pkg_list
		for tmp_ne in config_file.getSectionValue('NE-COMPONENT-REF'):
			tmp_ne_list = config_file.getSectionKeyValue('NE-COMPONENT-REF', tmp_ne).split(',')
			for com_pkg in com_pkg_list:
				if tmp_ne_list.count(com_pkg) == 1:
					return_ne_list.append(tmp_ne)
	del config_file
	return uniqueList(return_ne_list)

################################################################################
#CLASS NAME : NEInformation
#DESCRIBE   : The Class is used by analysing NE. The class will saved the information
#			  you selected by the NAME of NEType, it be required by NEType. the information
#			  is ip and machine type.
#FUNCTIONS  : __init__, printf, isSelectedNone, isCold, isHot, isSingle, isCluster,
#			  isHotCluster,isColdCluster,isSingleCluster, getActualIpList, getIpList,
#             getAllInformation.
#VARIABLE   : single_list, cold_list, hot_list.
################################################################################
class NEInformation:
	def __init__(self, _sid, NEType):
		self.single_list = []
		self.cold_list = []
		self.hot_list = []
		
		neinfo_util = OnlineNEInfoUtil(_sid)
		host_util = OnlineHostUtil(_sid, 1)
		info_list = neinfo_util.getNEInfoByType(NEType)
		
		if info_list is None:
			return 
		host_id_list = []
		for temp_info in info_list:
			host_id_list.append(temp_info.getHostId())
		#print host_id_list
		remove_list = []
		for tmp_host_id in host_id_list:
			host_bean = host_util.getHostBeanById(tmp_host_id)
			if host_bean.isDualHost():
				dual_host = host_util.getDualHostBySingleHostID(tmp_host_id)
				master_host_bean = dual_host.getMasterHost()
				slave_host_bean = dual_host.getSlaveHost()
				#print master_host_bean.getHostId()
				#print slave_host_bean.getHostId()
				if host_id_list.count(str(master_host_bean.getHostId())) and host_id_list.count(str(slave_host_bean.getHostId())):
					mast_ip = master_host_bean.getAddress()
					mast_username = master_host_bean.getUserName()
					slav_ip = slave_host_bean.getAddress()
					slav_username = slave_host_bean.getUserName()
					if dual_host.getDualHostType() == 'coldDualHost':
						self.cold_list.append((dual_host.getFloatIp(),mast_ip+'_'+mast_username, slav_ip+'_'+slav_username))
					else:
						self.hot_list.append((dual_host.getFloatIp(),mast_ip+'_'+mast_username, slav_ip+'_'+slav_username))
					remove_list.append(tmp_host_id)
					if tmp_host_id == str(master_host_bean.getHostId()):
						host_id_list.remove(str(slave_host_bean.getHostId()))
					else:
						host_id_list.remove(str(master_host_bean.getHostId()))
		
		for remove_host in remove_list:
			host_id_list.remove(remove_host)
		
		for single_host in host_id_list:
			self.single_list.append(host_util.getHostBeanById(single_host).getAddress()+'_'+host_util.getHostBeanById(single_host).getUserName())

	################################################################################
	#FUNCTION NAME : printf
	#DESCRIBE	   : The function can print the three list, it only can be used in 
	#                the debuging time.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : 
	################################################################################
	def printf(self):
		print self.single_list
		print self.cold_list
		print self.hot_list

	################################################################################
	#FUNCTION NAME : isSelectedNone
	#DESCRIBE	   : If the NE is selected NO machine, return true. or return False.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : True or False
	################################################################################
	def isSelectedNone(self):
		if len(self.single_list) + len(self.cold_list) + len(self.hot_list) == 0:
			return True
		else:
			return False

	################################################################################
	#FUNCTION NAME : isCold
	#DESCRIBE	  : Give the neType whether is cold dual host.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isCold(self):
		if len(self.single_list) == 0 and len(self.hot_list) == 0 and len(self.cold_list) == 1:
			return True
		else:
			return False

	################################################################################
	#FUNCTION NAME : isHot
	#DESCRIBE	  : Give the neType whether is hot dual host.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isHot(self):
		if len(self.single_list) == 0 and len(self.hot_list) == 1 and len(self.cold_list) == 0:
			return True
		else:
			return False

	################################################################################
	#FUNCTION NAME : isSingle
	#DESCRIBE	  : Give the neType whether is cold single machine.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isSingle(self):
		if len(self.single_list) == 1 and len(self.hot_list) == 0 and len(self.cold_list) == 0:
			return True
		else:
			return False

	################################################################################
	#FUNCTION NAME : isCluster
	#DESCRIBE	   : Find the neType whether is cluster.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isCluster(self):
		if self.isHotCluster() or self.isColdCluster() or self.isSingleCluster():
			return True
		else:
			return False
			

	################################################################################
	#FUNCTION NAME : isHotCluster
	#DESCRIBE	   : Find the NE is hot cluster or not. It only used by NE CBP.
	#                You can develop a function isColdCluster in the same way.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isHotCluster(self):
		if len(self.single_list) == 0 and len(self.hot_list) > 1 and len(self.cold_list) == 0:
			return True
		else:
			return False
			
	################################################################################
	#FUNCTION NAME : isColdCluster
	#DESCRIBE	   : Find the NE is cold cluster or not. It only used by NE CBP.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isColdCluster(self):
		if len(self.single_list) == 0 and len(self.hot_list) == 0 and len(self.cold_list) > 1:
			return True
		else:
			return False
			
	################################################################################
	#FUNCTION NAME : isSingleCluster
	#DESCRIBE	   : Find the NE is single cluster or not. It only used by NE CBP.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isSingleCluster(self):
		if len(self.single_list) > 1 and len(self.hot_list) == 0 and len(self.cold_list) == 0:
			return True
		else:
			return False

	################################################################################
	#FUNCTION NAME : isHaveDualHost
	#DESCRIBE	   : Find the NE is having dual host or not. 
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return True or False
	################################################################################
	def isHaveDualHost(self):
		if len(self.hot_list) > 0 or len(self.cold_list) > 0:
			return True
		else:
			return False
		
	################################################################################
	#FUNCTION NAME : getActualIpList
	#DESCRIBE	   : return the ip list. convert dual host float ip to master ip and slave ip.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################
	def getActualIpList(self):
		return_all_ip_list = []
		for tmp_single in self.single_list:
			tmp_single_list = tmp_single.split('_')
			return_all_ip_list.append(tmp_single_list[0])
		
		for tmp_cold in self.cold_list:
			tmp_cold_list = tmp_cold[1].split('_')
			return_all_ip_list.append(tmp_cold_list[0])
			tmp_cold_list = tmp_cold[2].split('_')
			return_all_ip_list.append(tmp_cold_list[0])
		
		for tmp_hot in self.hot_list:
			tmp_hot_list = tmp_hot[1].split('_')
			return_all_ip_list.append(tmp_hot_list[0])
			tmp_hot_list = tmp_hot[2].split('_')
			return_all_ip_list.append(tmp_hot_list[0])
		
		return return_all_ip_list

	################################################################################
	#FUNCTION NAME : getIpList
	#DESCRIBE	   : return the single machine's ip and dual host's float ip
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################
	def getIpList(self):
		return_ip_list = []
		
		for tmp_ip_single in self.single_list:
			tmp_single_ip_list = tmp_ip_single.split('_')
			return_ip_list.append(tmp_single_ip_list[0])
			
		for tmp_ip_cold in self.cold_list:
			return_ip_list.append(tmp_ip_cold[0])
		
		for tmp_ip_hot in self.hot_list:
			return_ip_list.append(tmp_ip_hot[0])
			
		return return_ip_list
	################################################################################
	
	################################################################################
	#FUNCTION NAME : getFloatIpList
	#DESCRIBE	   : return dual host's float ip list
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################
	def getFloatIpList(self):
		return_float_ip_list = []
			
		for tmp_ip_cold in self.cold_list:
			return_float_ip_list.append(tmp_ip_cold[0])
		
		for tmp_ip_hot in self.hot_list:
			return_float_ip_list.append(tmp_ip_hot[0])
			
		return return_float_ip_list

	################################################################################
	#FUNCTION NAME : getAllInformation
	#DESCRIBE	   : return a string. The string is format is defined as:
	#				 single:10.10.10.1_wy
	#				 cold:10.10.20.1/10.10.20.2_wy/10.10.20.3_wy
	#				 hot:10.10.20.4/10.10.20.5_wy/10.10.20.6_wy
	#				 single:10.10.10.1_wy| cold:10.10.20.1/10.10.20.2_wy/10.10.20.3_wy| hot:10.10.20.4/10.10.20.5_wy/10.10.20.6_wy
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : string
	################################################################################
	def getAllInformation(self):
		return_string = ''
		for tmp_single_info in self.single_list:
			if return_string == '':
				return_string = 'single:'+tmp_single_info
			else:
				return_string = return_string + '|single:'+tmp_single_info
				
		for tmp_cold_info in self.cold_list:
			if return_string == '':
				return_string = 'cold:' + tmp_cold_info[0]+'/'+tmp_cold_info[1]+'/'+tmp_cold_info[2]
			else:
				return_string = return_string + '|cold:' + tmp_cold_info[0]+'/'+tmp_cold_info[1]+'/'+tmp_cold_info[2]
				
		for tmp_hot_info in self.hot_list:
			if return_string == '':
				return_string = 'hot:' + tmp_hot_info[0]+'/'+tmp_hot_info[1]+'/'+tmp_hot_info[2]
			else:
				return_string = return_string + '|hot:' + tmp_hot_info[0]+'/'+tmp_hot_info[1]+'/'+tmp_hot_info[2]
				
		return return_string

	################################################################################
	#FUNCTION NAME : stringSingleList
	#DESCRIBE	   : return single_list
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################
	def stringSingleList(self):
		return self.single_list

	################################################################################
	#FUNCTION NAME : stringColdList
	#DESCRIBE	   : return cold_list
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################		
	def stringColdList(self):
		return self.cold_list

	################################################################################
	#FUNCTION NAME : stringHotList
	#DESCRIBE	   : return hot_list
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : ip list
	################################################################################		
	def stringHotList(self):
		return self.hot_list

###########################################################################
#FUNCTION NAME : DEBUGRUNLOG
#DESCRIBE	   : debug version DEBUGRUNLOG. If you are debuging, please use this 
#				version and comment the release version,else use the release version
#PARAMETER IN  : *loginfo
#PARAMETER OUT :
#RETURN VALUE  : 
###########################################################################
def DEBUGRUNLOG(*loginfo):
	debug_msg = ''
	print '[' + strftime("%Y-%m-%d %H:%M:%S", localtime()) + ']',
	for print_info in loginfo:
		print print_info,
		debug_msg = debug_msg + str(print_info)
	OnlineConfigLog.debug(debug_msg)
	print

###########################################################################
#FUNCTION NAME : DEBUGRUNLOG
#DESCRIBE	   : release version DEBUGRUNLOG. If The version is releasd, please use this 
#				version and comment the debug version,else use the debug version.
#PARAMETER IN  : *loginfo
#PARAMETER OUT :
#RETURN VALUE  : 
###########################################################################
# def DEBUGRUNLOG(*loginfo):
	# pass

###########################################################################
#FUNCTION NAME : RUNLOG
#DESCRIBE	   : print the information for developer.
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : 
###########################################################################

def RUNLOG(*loginfo):
	info_msg = ''
	print '[' + strftime("%Y-%m-%d %H:%M:%S", localtime()) + ']',
	for print_info in loginfo:
		print print_info,
		info_msg = info_msg + str(print_info)
	OnlineConfigLog.info(info_msg)
	print

	
###########################begin modify: service ip  ##############################
################################################################################
#FUNCTION NAME : getServiceFloatIpList
#DESCRIBE	   : return dual host's service float ip list
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : ip list
################################################################################		
def getServiceFloatIpList(_sid,ne_info_dict):
	service_float_ip = []
	neinfo_util = OnlineNEInfoUtil(_sid)
	config_util = OnlineConfigUtil(_sid)

	install_ne=neinfo_util.getAttributeValue('_selectedNetType')
	DEBUGRUNLOG("print all NE list information")
	DEBUGRUNLOG(neinfo_util.getAttributeValue('_selectedNETypeList').split(','))
	for NeTYPT in neinfo_util.getAttributeValue('_selectedNETypeList').split(','):
		if not ne_info_dict[NeTYPT].isSingle():
			if NeTYPT != 'SLB' and NeTYPT != 'OM':
				continue
			
			service_ip = getServiceIpListByNE(_sid,NeTYPT)	
			service_float_ip.extend(service_ip)
		
	return service_float_ip

################################################################################
#FUNCTION NAME : changeNeName
#DESCRIBE	   : change ne name
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : ne name
################################################################################
def changeNeName(tmp_ne_name):
	ne_name_tmp = ''
	
	if tmp_ne_name == "MDMC_ALL":
		ne_name_tmp = "mc"
	elif tmp_ne_name == "Charging_with_Dccproxy":
		ne_name_tmp = "chg"
	elif tmp_ne_name == "CGW":
		ne_name_tmp = "cgw1"		
	else:
		ne_name_tmp = tmp_ne_name.lower()
		
	print "changeNeName,ne_name_tmp=",ne_name_tmp	
	return ne_name_tmp
	
################################################################################
#FUNCTION NAME : getServiceIpListByNE
#DESCRIBE	   : single: return serivice host ip; dual: return service float ip
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : ip list
################################################################################
def getServiceIpListByNE(_sid,tmp_ne_name):
	neinfo_util = OnlineNEInfoUtil(_sid)
	config_util = OnlineConfigUtil(_sid)
	ne_all_ip_list = []
	print "getServiceIpListByNE: ne_name=",tmp_ne_name
	ne_name = changeNeName(tmp_ne_name)
		
	ne_list = interList([tmp_ne_name], neinfo_util.getAttributeValue('_selectedNETypeList').split(','))
	ne_num = len(NEInformation(_sid, ne_list[0]).getIpList())	
	ne_key = "service_" + ne_name + "_ip"
	
	ne_index = 0
	while ne_index < ne_num:
		service_ip = config_util.getValue(ne_key,ne_index,0)
		ne_all_ip_list.append(service_ip)
		
		ne_index = ne_index + 1
		
	print "getServiceIpListByNE,ne_all_ip_list="
	print ne_all_ip_list
	return uniqueList(ne_all_ip_list)	

	
################################################################################
#FUNCTION NAME : getServiceActualIpByNe
#DESCRIBE	   : single: return serivice host ip; dual: return service host ip,standby ip
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : ip list: single:10.137.163.26|10.137.163.27,cold:10.137.163.26/10.137.163.27|10.137.163.33/10.137.163.34
################################################################################		
def getServiceActualIpByNe(_sid,ne_name,ne_info_dict):
	service_actual_ip_list = ""
	neinfo_util = OnlineNEInfoUtil(_sid)
	config_util = OnlineConfigUtil(_sid)

	single_list_value = ne_info_dict[ne_name].stringSingleList()

	ne_name_value = changeNeName(ne_name)

	ne_list = interList([ne_name], neinfo_util.getAttributeValue('_selectedNETypeList').split(','))
	ne_num = len(NEInformation(_sid, ne_list[0]).getIpList())	

	print "ne_num: ",ne_num
	print "getServiceActualIpByNe,ne_name",ne_name
	tmp_idx=0
	while tmp_idx < ne_num:
		if len(single_list_value) > 0:
			print "getServiceActualIpByNe=,isSingle",ne_name
			service_ip = config_util.getValue('service_' + ne_name_value + '_ip',tmp_idx,0)
			if service_actual_ip_list == "":
				service_actual_ip_list = service_ip
			else:
				service_actual_ip_list = service_actual_ip_list + '|' + service_ip
		else:
			print "getServiceActualIpByNe=,isCold"
			host_ip = config_util.getValue('service_host_' + ne_name_value + '_ip',tmp_idx,0)
			standy_ip = config_util.getValue('service_standby_' + ne_name_value + '_ip',tmp_idx,0)
			if service_actual_ip_list == "":
				service_actual_ip_list = host_ip + '/' + standy_ip
			else:
				service_actual_ip_list = service_actual_ip_list + '|' + host_ip + '/' + standy_ip

		tmp_idx += 1
	
	return service_actual_ip_list

################################################################################
#FUNCTION NAME : getBaseActualIpByNe
#DESCRIBE	   : single: return base host ip; dual: return base host ip,standby ip
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : ip list: single:192.168.1.1|192.168.1.2,cold:192.168.1.1/192.168.1.2|192.168.1.7/192.168.1.8
################################################################################		
def getBaseActualIpByNe(_sid,ne_name,ne_info_dict):
	base_actual_ip_list = ""
	neinfo_util = OnlineNEInfoUtil(_sid)
	config_util = OnlineConfigUtil(_sid)
	
	single_list_value = ne_info_dict[ne_name].stringSingleList()
	
	ne_name_value = changeNeName(ne_name)
		
	ne_list = interList([ne_name], neinfo_util.getAttributeValue('_selectedNETypeList').split(','))
	ne_num = len(NEInformation(_sid, ne_list[0]).getIpList())	

	print "ne_num: ",ne_num
	tmp_idx=0
	while tmp_idx < ne_num:
		if len(single_list_value) > 0:
			base_ip = config_util.getValue('base_' + ne_name_value + '_ip',tmp_idx,0)
			if base_actual_ip_list == "":
				base_actual_ip_list = base_ip
			else:
				base_actual_ip_list = base_actual_ip_list + '|' + base_ip
		else:	
			base_host_ip = config_util.getValue('base_host_' + ne_name_value + '_ip',tmp_idx,0)
			base_standy_ip = config_util.getValue('base_standby_' + ne_name_value + '_ip',tmp_idx,0)
			if base_actual_ip_list == "":
				base_actual_ip_list = base_host_ip + '/' + base_standy_ip
			else:
				base_actual_ip_list = base_actual_ip_list + '|' + base_host_ip + '/' + base_standy_ip

		tmp_idx += 1
	
	return base_actual_ip_list
	
	
################################################################################
#FUNCTION NAME : getAllServiceInformation
#DESCRIBE	   : return a service  string. The string is format is defined as:
#				 single:10.10.10.1_wy
#				 cold:10.10.20.1/10.10.20.2_wy/10.10.20.3_wy
#				 hot:10.10.20.4/10.10.20.5_wy/10.10.20.6_wy
#				 single:10.10.10.1_wy| cold:10.10.20.1/10.10.20.2_wy/10.10.20.3_wy| hot:10.10.20.4/10.10.20.5_wy/10.10.20.6_wy
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : string
################################################################################
def getAllServiceInformation(_sid,ne_name,ne_info_dict):
	return_string = ''
	config_util = OnlineConfigUtil(_sid)
	neinfo_util = OnlineNEInfoUtil(_sid)

	single_list_value = ne_info_dict[ne_name].stringSingleList()
	cold_list_value = ne_info_dict[ne_name].stringColdList()
	hot_list_value = ne_info_dict[ne_name].stringHotList()
	
	ne_name_value = changeNeName(ne_name)

	tmp = 0
	for tmp_single_info in single_list_value:
		service_ip = config_util.getValue("service_" + ne_name_value + "_ip",tmp,0)
		user_name_tmp = tmp_single_info.split('_')
		user_name = user_name_tmp[1]
		if return_string == '':
			return_string = 'single:' + service_ip + "_" + user_name
		else:
			return_string = return_string + '|single:' + service_ip + "_" + user_name
		
		tmp = tmp + 1
		
	tmp = 0
	for tmp_cold_info in cold_list_value:
		user_name_tmp = tmp_cold_info[1].split('_')
		user_name1 = user_name_tmp[1]
		user_name_tmp2 = tmp_cold_info[2].split('_')
		user_name2 = user_name_tmp[1]		
		install_ip = config_util.getValue(ne_name_value + "_install_ip",tmp,0)
		service_ip = config_util.getValue("service_" + ne_name_value + "_ip",tmp,0)	
		host_ip = config_util.getValue("service_host_" + ne_name_value + "_ip",tmp,0)
		standby_ip = config_util.getValue("service_standby_" + ne_name_value + "_ip",tmp,0)
		string_value = service_ip +'/'+ host_ip + '_' + user_name1 + '/' + standby_ip + '_' + user_name2
		if return_string == '':
			return_string = 'cold:' + string_value
		else:
			return_string = return_string + '|cold:' + string_value
					
		tmp = tmp + 1
	
	tmp = 0
	for tmp_hot_info in hot_list_value:
		user_name_tmp = tmp_hot_info[1].split('_')
		user_name1 = user_name_tmp[1]
		user_name_tmp = tmp_hot_info[2].split('_')
		user_name2 = user_name_tmp[1]
		install_ip = config_util.getValue(ne_name_value + "_install_ip",tmp,0)
		service_ip = config_util.getValue("service_" + ne_name_value + "_ip",tmp,0)
			
		host_ip = config_util.getValue("service_host_" + ne_name_value + "_ip",tmp,0)
		standby_ip = config_util.getValue("service_standby_" + ne_name_value + "_ip",tmp,0)
		string_value = service_ip +'/'+ host_ip + '_' + user_name1 + '/' + standby_ip + '_' + user_name2
		if return_string == '':
			return_string = 'cold:' + string_value
		else:
			return_string = return_string + '|cold:' + string_value
					
		tmp = tmp + 1
		
	return return_string

	
##################################end modify for: service ip######################

		



