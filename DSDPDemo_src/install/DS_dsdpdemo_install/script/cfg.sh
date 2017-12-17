#!/bin/sh 

function show_help
{	
    echo "Usage:  cfg <moduleName>"
    echo "Example:"
    echo "    cfg order"	
    echo "<moduleName> is one of :$compNameList"
    echo " 																													 "
}
# shell file path
APP_HOME=$(cd "$(dirname "$0")"; pwd)

typeset comp_name=$1
typeset compNameList=`cat $APP_HOME/compinfo.cfg | grep "\["  | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'|grep -iv uniagent|grep -iv monitor` 

#check comp name; right 0, wrong 1
CheckCompName()
{    
    compNameList=$compNameList
    for line in $compNameList
    do
        echo $line |grep -iw $1 >>/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 0 
        fi  
    done    
    
    return 1
}

if [ "X${comp_name}" == "X" ];then
    show_help 
    typeset comp_count=`echo $compNameList|wc -w`
    if [ $comp_count -gt 1 ];then        
        exit 1
    fi  
else
    CheckCompName $comp_name
    if [ $? -ne 0 ];then
        echo "ERROR:" "Module name \"${comp_name}\" does not exist."
        echo "<moduleName> is one of :$compNameList"
        exit 1
    fi
fi

exit 0
