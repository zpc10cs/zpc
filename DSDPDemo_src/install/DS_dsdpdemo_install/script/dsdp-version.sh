#!/usr/bin/ksh
###############################################################################
# script name: dsdp-version.sh
# description: 
# parameters : [-v|-h|-p|-his] or null
# output     : display baseline,component or update version info
# return     : 0 succ, 1 fail
###############################################################################
cd $(dirname "$0")

typeset version_info_path="${HOME}/dsdp-version"

function display_total_version
{
	typeset baseline_version_files=$(find ${version_info_path} -maxdepth 1 -name "onesdp-baseline-*-version.cfg")
	typeset custom_version_files=$(find ${version_info_path} -maxdepth 1 -name "onesdp-customize-*-version.cfg")
    typeset tmp_version_file="${version_info_path}/tmp_version_file"
    typeset version_separator="
-------------------------------------------------------------------------------\n
BASELINE\n
-------------------------------------------------------------------------------\n
"
   typeset custom_version_separator="
-------------------------------------------------------------------------------\n
\nCUSTOMIZE\n
-------------------------------------------------------------------------------\n
"
	echo "" > ${tmp_version_file}
    
	typeset comp_version_desc="-- component version"
	if [ "x${baseline_version_files}" != "x" ];then
		echo ${version_separator} >> ${tmp_version_file}
		for version_file in ${baseline_version_files}
		do
			typeset prefix=$(echo ${version_file}| awk -F/ '{print $NF}'|cut -d- -f3|tr 'a-z' 'A-Z')
			echo "${prefix}:$(cat ${version_file})" >> ${tmp_version_file}
		done
	fi
	if [ "x${custom_version_files}" != "x" ];then
		echo ${custom_version_separator} >> ${tmp_version_file}
		for vfile in ${custom_version_files}
		do
			typeset prefix=$(echo ${vfile}|awk -F/ '{print $NF}'|cut -d- -f3|tr 'a-z' 'A-Z')
			echo "${prefix}:$(cat ${vfile})" >> ${tmp_version_file}
		done
	fi
	
	#solve iptv custome version
	if [ -f ${version_info_path}/customize-version.cfg ];then
		typeset all_customize_version=$(cat ${version_info_path}/customize-version.cfg)
		if [ "x${all_customize_version}" != "x" ];then
				echo "${all_customize_version}" >> ${tmp_version_file}
		fi
	fi
	
    format_version_info ${tmp_version_file}  
    rm -rf ${tmp_version_file}
    return 0
}

function display_componet_version
{
    typeset baseline_version_files=$(find ${version_info_path} -maxdepth 1 -name "onesdp-baseline-*-version.cfg")
	typeset custom_version_files=$(find ${version_info_path} -maxdepth 1 -name "onesdp-customize-*-version.cfg")
    typeset tmp_version_file="${version_info_path}/tmp_version_file"
    typeset version_separator="
-------------------------------------------------------------------------------\n
BASELINE\n
-------------------------------------------------------------------------------\n
"
   typeset custom_version_separator="
-------------------------------------------------------------------------------\n
\nCUSTOMIZE\n
-------------------------------------------------------------------------------\n
"
	echo "" > ${tmp_version_file}
	typeset comp_version_desc="-- component version"
	if [ "x${baseline_version_files}" != "x" ];then
		echo ${version_separator} >> ${tmp_version_file}
		for version_file in ${baseline_version_files}
		do
			typeset prefix=$(echo ${version_file}| awk -F/ '{print $NF}'|cut -d- -f3|tr 'a-z' 'A-Z')
			echo "${prefix}:$(cat ${version_file})" >> ${tmp_version_file}
		done
	fi
	if [ "x${custom_version_files}" != "x" ];then
		echo ${custom_version_separator} >> ${tmp_version_file}
		for vfile in ${custom_version_files}
		do
			typeset prefix=$(echo ${vfile}|awk -F/ '{print $NF}'|cut -d- -f3|tr 'a-z' 'A-Z')
			echo "${prefix}:$(cat ${vfile})" >> ${tmp_version_file}
		done
	fi
	
	#solve iptv custome version
	if [ -f ${version_info_path}/customize-version.cfg ];then
		typeset all_customize_version=$(cat ${version_info_path}/customize-version.cfg)
		if [ "x${all_customize_version}" != "x" ];then
				echo "${all_customize_version}" >> ${tmp_version_file}
		fi
	fi
	
    format_version_info ${tmp_version_file}  
    rm -rf ${tmp_version_file}
    return 0
}

function format_version_info
{
	typeset version_file="$1"
	
    dos2unix -n "${version_file}" "${version_file}_$$" >/dev/null 2>&1
	cp "${version_file}_$$" "${version_file}"
	rm "${version_file}_$$"
    
	cat ${version_file} | sed 's/^[ \t]*//g' | sed 's/[ \t]*$//g' | sed '/^#/d' |  sed '/^[ \t]*$/d' | awk --posix '{
        if(NF < 2)
        {
                print toupper($0);
                next;
        }

        buff = "";
        for(i=1;i<NF;i++)
        {
                buff = buff toupper($i);
                if(i < NF-1)
                {
                        buff = buff " ";
                }
        }
        if($NF ~ /[0-9]{4}-[0-9]{1,2}-[0-9]{1,2}/)
        {
                len = 80 - length(buff) - length($NF);
                while(len > 1)
                {
                        buff = buff " ";
                        len = len - 1;
                }
                buff = buff $NF;
        }
        else
        {
                buff = buff " " toupper($NF);
        }

        print buff;
}'
}

function display_updatepkg_info
{
    typeset updatepkf_info="${version_info_path}/patch-update.cfg"
    
    if [ -f ${updatepkf_info} ];then
        cat ${updatepkf_info}
    else
        return 1
    fi
    
    return 0
}

function display_updatehis_info
{
    typeset updatehis_info="${version_info_path}/patch-history.cfg"
    
    if [ -f ${updatehis_info} ];then
        cat ${updatehis_info}
    else
        return 1
    fi
    
    return 0
}

function display_version_history
{
	typeset version_history="${version_info_path}/version-history.cfg"
    
    if [ -f ${version_history} ];then
        cat ${version_history}
    else
        return 1
    fi
    
    return 0
}

function display_usage
{
    echo "Usage:version [-v|-p|-ph|-his|-h]\n\
    \t-p:display the update pkg info\n\
    \t-ph:display the update pkg history info\n\
    \t-v:display the component version info\n\
    \t-his:display the history of version info\n\
    \t-h:display the usage of version command"
    return 0
}

function main
{
    if [ $# -eq 0 ];then
        display_total_version
        if [ $? -ne 0 ];then
            echo "null total version info was found."
        fi        
    elif [ $# -eq 1 ];then
        case $1 in
            -p|-P)
            display_updatepkg_info
            if [ $? -ne 0 ];then
                echo "the current system has not been updated."
            fi
            ;;
			-ph)
            display_updatehis_info
            if [ $? -ne 0 ];then
                echo "the current system has not been updated."
            fi
            ;;
            -v|-V)
            display_componet_version
            if [ $? -ne 0 ];then
                echo "null componet version info was found."
            fi
            ;;
			-his)
            display_version_history
            if [ $? -ne 0 ];then
                echo "null  version history info was found."
            fi
            ;;
            *)
            display_usage
            ;;
        esac
    else
        display_usage
    fi
    
    return 0
}

main "$@"


