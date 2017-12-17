import os
import javapath as path
import user_info

#获取两个数组的公共元素    
def getCommonItemBetweenList(list1,list2):
    commonItemString = None
    longList = len(list1) >= len(list2) and list1 or list2
    shortList = len(list1) >= len(list2) and list2 or list1
    for item in longList:
        if item in shortList:
            if None == commonItemString:
                commonItemString = item
            else:
                commonItemString = commonItemString + "," + item
    return commonItemString

#获取可动态配置用户名的所有网元    
def getAllAppCompment():
    allAppCompment = None
    for key in user_info.default_user_config_dic.keys():
        if None == allAppCompment:
            allAppCompment = user_info.default_user_config_dic[key].split(":")[0]
        else:
            allAppCompment = allAppCompment + "," + user_info.default_user_config_dic[key].split(":")[0]    
    return allAppCompment    

#获取所有连接Oracle数据库的网元    
def getAllConnectOracleCompment():
    allConnectOracleCompment = []
    for key in user_info.default_db_user_config_dic.keys():
        for compment in user_info.default_db_user_config_dic[key].split(":")[0].split(","):
            if compment not in allConnectOracleCompment:
                allConnectOracleCompment.append(compment)    
    return allConnectOracleCompment
    
################################################################################
#FUNCTION NAME : uniqueList
#DESCRIBE	   : Give a list, the list maybe have two same element, return a list.
#                the list 's each element is only one. 
#PARAMETER IN  : input_list
#PARAMETER OUT :
#RETURN VALUE  : return_list, the list's each element is unique.
################################################################################
def uniqueList(input_list):
	return_list = []
	length = len(input_list)
	input_list.sort()
	tmp = 0
	while tmp < length:
		return_list.append(input_list[tmp])
		tmp += input_list.count(input_list[tmp])
	return return_list

################################################################################
#FUNCTION NAME : interList
#DESCRIBE	   : Give two list, the two list maybe have same element, return a list.
#                the list 's each element is both in first_list and second_list.
#PARAMETER  IN : first_list, second_list
#PARAMETER OUT :
#RETURN VALUE  : same_list,the list is first_list and second_list 's intersection.
################################################################################
def interList(first_list, second_list):
	same_list = []
	first_list.sort()
	second_list.sort()
	first_list_length = len(first_list)
	second_list_length = len(second_list)
	tmp_first_list = 0
	tmp_second_list = 0
	while tmp_first_list < first_list_length and tmp_second_list < second_list_length:
		compare_value = cmp(first_list[tmp_first_list], second_list[tmp_second_list])
		if compare_value == 0:
			same_list.append(first_list[tmp_first_list])
			tmp_first_list += 1
			tmp_second_list += 1
		elif compare_value < 0:
			tmp_first_list += 1
		else:
			tmp_second_list += 1
	return same_list


################################################################################
#FUNCTION NAME : compareList
#DESCRIBE	   : Give two list, the two list maybe have same element, if the have
#                one same element, return False,or return True.
#PARAMETER  IN : first_list, second_list.
#PARAMETER OUT :
#RETURN VALUE  : True or False
################################################################################
def compareList(first_list, second_list):
	first_list.sort()
	second_list.sort()
	first_list_length = len(first_list)
	second_list_length = len(second_list)
	tmp_first_list = 0
	tmp_second_list = 0
	while tmp_first_list < first_list_length and tmp_second_list < second_list_length:
		compare_value = cmp(first_list[tmp_first_list], second_list[tmp_second_list])
		if compare_value == 0:
			return False
		elif compare_value < 0:
			tmp_first_list += 1
		else:
			tmp_second_list += 1
	return True


###########################################################################
#FUNCTION NAME : getAbsolutPath
#DESCRIBE	  : Give the currentPath and the comparativePath, the function
#				will give you a absolute path.
#PARAMETER IN  : 
#PARAMETER OUT :
#RETURN VALUE  : resultPath, the absolute path of you gived.
###########################################################################
def getAbsolutPath(currentPath, comparativePath):
	tmpPath = comparativePath.split('/')
	resultPath = currentPath
	for x in tmpPath:
		if('..' == x):
			resultPath, tmp = path.split(resultPath)
		else:
			resultPath = path.join(resultPath, x)
	return resultPath

###############################################################################
#CLASS NAME : PathError
#DESCRIBE   : The Class is just raising a execpt.using by IniFile.
#			  if a file's path is not existed, IniFile will raise it.
#FUNCTIONS  : 
#VARIABLE   : 
###############################################################################
class PathError:
	pass

###############################################################################
#CLASS NAME : IniFile
#DESCRIBE   : The Class is used by analysing ini files. It can get all section 
#			  names, touch the keys of the selected section name, reach the 
#			  value of the one section name's key.
#FUNCTIONS  : getAllSectionName, printData, getSectionInfo, getSectionValue, 
#			  getSectionKeyValue, del
#VARIABLE   : file, data, is_data_exist.
###############################################################################
class IniFile:
	###########################################################################
	#FUNCTION NAME : __init__
	#DESCRIBE	   : Construct function
	#PARAMETER	   : complete_file_path, the ini file's complete path
	#PARAMETER OUT :
	#RETURN VALUE  :
	###########################################################################
	def __init__(self, complete_file_path):
		self.is_data_exist = False
		if not path.exists(complete_file_path):
			raise PathError
		else:
			self.is_data_exist = True
			self.the_file = open(complete_file_path)
			self.data = self.the_file.readlines()

	###########################################################################
	#FUNCTION NAME : printData
	#DESCRIBE	   : print all of the ini file's information. Just using in debuging.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  :
	###########################################################################
	def printData(self):
		RUNLOG(self.data)

	###########################################################################
	#FUNCTION NAME : getAllSectionName
	#DESCRIBE	   : The function is order to get all of the ini file's section
	#				 name.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : return_list, the list of the section names in the ini file
	###########################################################################
	def getAllSectionName(self):
		return_list = []
		for x in self.data:
			if x[0] == '[' and x[len(x)-2:len(x)] == ']\n':
				return_list.append(x[1:len(x)-2])
		return return_list

	###########################################################################
	#FUNCTION NAME : getSectionInfo
	#DESCRIBE	   : Give one selected section name, return the index of the
	#				 section name.
	#PARAMETER IN  : section_name, the name of you selected section.
	#PARAMETER OUT :
	#RETURN VALUE  : sec_begin, the begin index; sec_end, the end index
	###########################################################################
	def getSectionInfo(self, section_name):
		tmp = 0
		sec_begin = 0
		sec_end   = 0
		self_data_length = len(self.data)
		while tmp < self_data_length:
			if str(self.data[tmp]) == '[' + section_name + ']\n':
				sec_begin = tmp
				break
			tmp += 1
		tmp += 1
		while tmp < self_data_length:
			tmp_str = self.data[tmp]
			#print tmp_str
			if tmp == self_data_length - 1:
				sec_end = self_data_length
			if tmp_str[0] == '[' and tmp_str[len(tmp_str)-2:len(tmp_str)] == ']\n':
				sec_end = tmp
				break			   
			tmp += 1
		return (sec_begin, sec_end)

	###########################################################################
	#FUNCTION NAME : getSectionValue
	#DESCRIBE	   : Give one selected section name, return the key's value under
	#				the selected section name.
	#PARAMETER IN  : section_name, the name of you selected section.
	#PARAMETER OUT :
	#RETURN VALUE  : return_list, the list of the key names under the section
	###########################################################################
	def getSectionValue(self, section_name):
		return_list = []
		sec_begin, sec_end = self.getSectionInfo(section_name)
		tmp = sec_begin + 1
		#print sec_end
		while tmp < sec_end:
			tmp_str = self.data[tmp]
			if tmp_str[0] != '#' and tmp_str[0] != '\n':
				tmp_list = tmp_str.split('=')
				return_list.append(tmp_list[0].strip())
			tmp += 1
		return return_list

	
	###########################################################################
	#FUNCTION NAME : getSectionKeyValue
	#DESCRIBE	   : Give one selected section name and one selected key name, 
	#				 return the selected key's value.
	#PARAMETER IN  : section_name, the name of you selected section.; key_name,
	#				the key name of you selected.
	#PARAMETER OUT :
	#RETURN VALUE  : return_str, the vaule of the key you selected.
	###########################################################################
	def getSectionKeyValue(self, section_name, key_name):
		return_str = ''
		sec_begin, sec_end = self.getSectionInfo(section_name)
		tmp = sec_begin + 1
		while tmp < sec_end:
			tmp_list = self.data[tmp].split('=')
			if tmp_list[0].strip() == key_name:
				return_str = tmp_list[1].strip()
			tmp += 1
		return return_str
	
	###########################################################################
	#FUNCTION NAME : isSectionExisted
	#DESCRIBE	   : Give one selected section name and estimate whether the 
	#				 section is existed.
	#PARAMETER IN  : section_name, the name of you selected section.
	#PARAMETER OUT :
	#RETURN VALUE  : return_section_existed, a bool vaule to show the section's status
	###########################################################################
	def isSectionExisted(self, section_name):
		return_section_existed = False
		for x in self.getAllSectionName():
			if section_name == x:
				return_section_existed = True
		return return_section_existed

	###########################################################################
	#FUNCTION NAME : isKeyExisted
	#DESCRIBE	   : Give one selected section name and one selected key name, 
	#				 return the selected key whether is existed.
	#PARAMETER IN  : section_name, the name of you selected section.; key_name,
	#				the key name of you selected.
	#PARAMETER OUT :
	#RETURN VALUE  : return_key_existed, a bool vaule to show the key's status
	###########################################################################
	def isKeyExisted(self, section_name, key_name):
		return_key_existed = False
		if not self.isSectionExisted(section_name):
			return False
		for xx in self.getSectionValue(section_name):
			if xx == key_name:
				return_key_existed = True
		return return_key_existed
	###########################################################################
	#FUNCTION NAME : __del__
	#DESCRIBE	   : destructure function, close the file you have opened. If the 
	#                is_data_exist is true. close the file you opened.
	#PARAMETER IN  : 
	#PARAMETER OUT :
	#RETURN VALUE  : 
	###########################################################################
	def __del__(self):
		if self.is_data_exist:
			self.the_file.close()


