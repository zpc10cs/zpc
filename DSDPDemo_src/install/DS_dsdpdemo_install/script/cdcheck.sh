#!/bin/ksh

typeset AWK="awk"
typeset SED="sed"
typeset file_name="$HOME/bin/compinfo.cfg"
typeset RETURN="" 
typeset path=""
typeset cmd=""

function get_all_comp
{
    typeset file_name=$1

    typeset complist=`
${AWK} -F# '{print $1}' "$file_name" |
${SED} '/^[     ]*$/d' |
${SED} -n "s/^\[\(.*\)\]$/\1/p"|
grep -v "monitor" |
grep -v "uniagent"
`            
    RETURN=${complist}
}


function get_path
{
    typeset file_name=$1
    typeset sec_name=$2
    typeset conf_name=$3
    typeset log_path=""
    typeset filelist=`
${AWK} -F# '{print $1}' "$file_name" |
${SED} '/^[     ]*$/d' |
${SED} -n "/^[     ]*\[[   ]*${sec_name}[  ]*\]/,/^[       ]*\[.*\]/p" |
${SED} '/^[        ]*\[.*\]/d' 
`
    for properties in $filelist
    do
        typeset k=`echo $properties | ${AWK} -F= '{print $1}'`
        typeset v=`echo $properties | ${AWK} -F= '{print $2}'`

        if [ "X$k" == "X$conf_name" ]; then
           log_path="$v" 
           break
        fi
    done
    if [ "X$log_path" != "X" ]; then
        path="${HOME}/$log_path"
    fi
}
 
function showHelp
{	
    typeset complist=$*
    typeset comp="$1"
    echo "Usage:  $cmd <moduleName>"
    echo "Example:"
    echo "    $cmd $comp"	
    echo "moduleName: $complist"
}

function main
{
    typeset conf_name=$1
    typeset sec_name=$2  
    typeset comp="" 
    typeset isComp="false" 

    cmd="$conf_name"

    get_all_comp $file_name
    typeset components="$RETURN"
    typeset compCount=`echo $components | awk '{print NF}'`
    if [ "X$sec_name" == "X" ]; then
       if [ "X$compCount" == "X1" ]; then
            isComp="true" 
            comp=`echo $components | awk '{print $1}'`
       else
            showHelp $components    
            exit 1
       fi 
    else
        for c in $components
        do
            if [ "X$c" == "X$sec_name" ]; then
                isComp="true"
                comp="$c"
                break
            fi 
        done
     fi

     if [ "X$isComp" == "Xfalse" ]; then
          showHelp $components
          exit 1
     fi 

     get_path $file_name $comp $conf_name
     if [ "X$path" == "X" ]; then
        echo "Error: $HOME/bin/compinfo.cfg segment $comp has no $conf_name define!\n"
        exit 1
     fi
     exit 0
}
main $*
return $?
