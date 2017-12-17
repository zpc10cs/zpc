#!/usr/bin/ksh
###############################################################################
# script name: version.sh
# description: 
# parameters : [-v|-h|-his]
# output     : display component  version info
# return     : 0 succ, 1 fail
###############################################################################
function display_componet_version
{
    typeset baseline_version_files=$(find ${HOME} -maxdepth 5 -name "*baseline-*-version.cfg")
	typeset custom_version_files=$(find ${HOME} -maxdepth 5 -name "customize-*-version.cfg")
	typeset platform_version_files=$(find ${HOME} -maxdepth 5 -name "platform-*-version.cfg")
	typeset -u base_name=$(find ${HOME} -maxdepth 5 -name "*baseline-*-version.cfg" | head -n 1|awk -F "-" '{print $2}')
	typeset flag=$(find ${HOME} -maxdepth 5 -name "*baseline-*-version.cfg" | head -n 1|awk -F "-" '{print $3}')
	typeset baseline=""
	if [ "x${base_name}" != "x" ];then
		if [ "x${flag}" != "xversion.cfg" ];then
			baseline=${base_name}" BASELINE"
		else 
			baseline="BASELINE"
		fi
	else
		baseline="BASELINE"
	fi 
	typeset customize="CUSTOMIZE"
	typeset platform="PLATFORM"
	typeset separator="-------------------------------------------------------------------------"
	
	typeset component
	typeset version
	typeset release_date
	typeset deploy_date
	typeset length_1
	typeset length_2
    
	if [ "x${platform_version_files}" != "x" ];then
		echo "${platform}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		
		for vfile in ${platform_version_files}
		do
			if [ -s ${vfile} ];then
				typeset vinfo=$(sed -n '1p' ${vfile})
				component=$(echo ${vinfo} | awk -F"|" '{print $1}')
				version=$(echo ${vinfo} | awk -F"|" '{print $2}')
				release_date=$(echo ${vinfo} | awk -F"|" '{print $3}')
				deploy_date=$(echo ${vinfo} | awk -F"|" '{print $4}')
				
				length_1=$(expr length "${component}")
				let length_1+=2
				let length_2=32-length_1
				printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
				printf "\r\n"
			fi
		done
	fi
	
	if [ "x${baseline_version_files}" != "x" ];then
		echo "${baseline}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		for version_file in ${baseline_version_files}
		do
			if [ -s ${version_file} ];then
				typeset version_info=$(sed -n '1p' ${version_file})
				component=$(echo ${version_info} | awk -F"|" '{print $1}')
				version=$(echo ${version_info} | awk -F"|" '{print $2}')
				release_date=$(echo ${version_info} | awk -F"|" '{print $3}')
				deploy_date=$(echo ${version_info} | awk -F"|" '{print $4}')
				
				length_1=$(expr length "${component}")
				let length_1+=2
				let length_2=32-length_1
				
				printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
				printf "\r\n"
			fi
		done
	fi	
	
	if [ "x${custom_version_files}" != "x" ];then
		echo ""
		echo "${customize}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		
		for vfile in ${custom_version_files}
		do
			if [ -s ${vfile} ];then
				typeset vinfo=$(sed -n '1p' ${vfile})
				component=$(echo ${vinfo} | awk -F"|" '{print $1}')
				version=$(echo ${vinfo} | awk -F"|" '{print $2}')
				release_date=$(echo ${vinfo} | awk -F"|" '{print $3}')
				deploy_date=$(echo ${vinfo} | awk -F"|" '{print $4}')
				
				length_1=$(expr length "${component}")
				let length_1+=2
				let length_2=32-length_1
				
				printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
				printf "\r\n"
			fi
		done
	fi
	echo ""
	
	
    return 0
}

function display_version_history
{
	typeset baseline_version_files=$(find ${HOME} -maxdepth 5 -name "*baseline-*-version.cfg")
	typeset custom_version_files=$(find ${HOME} -maxdepth 5 -name "customize-*-version.cfg")
	typeset platform_version_files=$(find ${HOME} -maxdepth 5 -name "platform-*-version.cfg")
	typeset -u base_name=$(find ${HOME} -maxdepth 5 -name "*baseline-*-version.cfg" | head -n 1|awk -F "-" '{print $2}')
	typeset baseline=""
	if [ "x${base_name}" != "x" ];then
		baseline=${base_name}" BASELINE"
	else
		baseline="BASELINE"
	fi 
	typeset customize="CUSTOMIZE"
	typeset platform="PLATFORM"
	typeset separator="-------------------------------------------------------------------------"
	
	typeset component
	typeset version
	typeset release_date
	typeset deploy_date
	typeset length_1
	typeset length_2
	
	if [ "x${platform_version_files}" != "x" ];then
		echo "${platform}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		
		for vfile in ${platform_version_files}
		do
			if [ -s ${vfile} ];then
				cat ${vfile} | while read line
				do
					component=$(echo ${line} | awk -F"|" '{print $1}')
					version=$(echo ${line} | awk -F"|" '{print $2}')
					release_date=$(echo ${line} | awk -F"|" '{print $3}')
					deploy_date=$(echo ${line} | awk -F"|" '{print $4}')
					
					length_1=$(expr length "${component}")
					let length_1+=2
					let length_2=32-length_1
					
					printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
					printf "\r\n"
				done
				echo ""
			fi
		done
	fi
	
	if [ "x${baseline_version_files}" != "x" ];then
		echo "${baseline}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		for version_file in ${baseline_version_files}
		do
			if [ -s ${version_file} ];then
				cat ${version_file} | while read line
				do
					component=$(echo ${line} | awk -F"|" '{print $1}')
					version=$(echo ${line} | awk -F"|" '{print $2}')
					release_date=$(echo ${line} | awk -F"|" '{print $3}')
					deploy_date=$(echo ${line} | awk -F"|" '{print $4}')

					length_1=$(expr length "${component}")
					let length_1+=2
					let length_2=32-length_1
					
					printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
					printf "\r\n"
				done
				echo ""
			fi
		done
	fi	
	
	if [ "x${custom_version_files}" != "x" ];then
		echo "${customize}"
		echo "${separator}"
		printf "%-15s%-17s%26s%15s" "+ version" " " "| release date " "| deploy date |"
		printf "\r\n"
		echo "${separator}"
		
		for vfile in ${custom_version_files}
		do
			if [ -s ${vfile} ];then
				cat ${vfile} | while read line
				do
					component=$(echo ${line} | awk -F"|" '{print $1}')
					version=$(echo ${line} | awk -F"|" '{print $2}')
					release_date=$(echo ${line} | awk -F"|" '{print $3}')
					deploy_date=$(echo ${line} | awk -F"|" '{print $4}')
					
					length_1=$(expr length "${component}")
					let length_1+=2
					let length_2=32-length_1
					
					printf "%-${length_1}s%-${length_2}s%26s%15s" ${component} ${version} ${release_date} ${deploy_date}
					printf "\r\n"
				done
				echo ""
			fi
		done
	fi
	
	
	
    return 0
}

function display_usage
{
    echo "Usage:version [OPTION]"
	echo "\t-v:display the current version info of all components"
	echo "\t-his:display the history version info of all components"
	echo "\t-h:display this help"
	
    return 0
}
function print_libs
{
    module_name=`ls $HOME|grep "_container"|awk -F_ '{print $1}'|head -n 1`
	echo "LIBS"
	echo "-----------------------------------"
	echo "--------- $module_name ------------"
	echo "-----------------------------------"
	find $HOME -name "*.jar" | grep ${module_name}_container | grep -E "/lib/usr|modules" |grep -v "${module_name}/tools/"	|xargs ls -l
    return 0
}

function main
{
    if [ $# -eq 0 ];then        
            echo "version: You must specify one option"
			echo "Try 'version -h' for more information."
    elif [ $# -eq 1 ];then
        case $1 in
			-v)
            display_componet_version
            if [ $? -ne 0 ];then
                echo "no componet version info found."
            fi
            ;;
			-his)
            display_version_history
            ;;
			-h)
            display_usage
			;;
			-lib)
            print_libs
            ;;
            *)
			echo "version: invalid option -- $@"
			echo "Try 'version -h' for more information."
            ;;
        esac	
    else
        echo "version: invalid option -- $@"
		echo "Try 'version -h' for more information."
    fi
    
    return 0
}

main "$@"
