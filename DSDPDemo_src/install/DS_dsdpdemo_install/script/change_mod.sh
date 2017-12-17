#!/bin/ksh

function change_mod
{
    user_home=$1
    if [ "x${user_home}" != "x" -a "x${user_home}" != "x/" ];then        
        chmod -R 750 ${user_home}        
        find ${user_home} -type f|grep -v bin|xargs chmod 640
        find ${user_home} -name bin -type d|xargs chmod -R 550 
        find ${user_home} -name shell -type d|xargs chmod -R 550
        find ${user_home} -name "*.sh"|xargs chmod 550
        find ${user_home} -type d|xargs chmod 750 
        find ${user_home} -name "*.log" -type f|grep /bin/|xargs chmod  640  > /dev/null 2>&1
        find ${user_home} -name "*.cfg" -type f|grep /bin/|xargs chmod  640  > /dev/null 2>&1
        find ${user_home} -name "*.properties" -type f|grep /bin/|xargs chmod  640  > /dev/null 2>&1
        find ${user_home} -name "*.config" -type f|grep /bin/|xargs chmod  640  > /dev/null 2>&1  
        find ${user_home} -name ideploy -type d|xargs chmod -R 750
    fi
    return 0
}
