#!/usr/bin/ksh

if [ `echo $0 | grep -c "/"` -gt 0 ];then
    cd ${0%/*}     
fi

. ./commonlib.inc

#./dsdp_stop.sh
#if [ $? -ne 0 ]; then
#     install_log "ERROR" "common_control" "Failed to invoke dsdp_stop.sh"
#     return 1
#fi
#sleep 3
typeset index=0
while [ $index -lt 20 ]
do
	./dsdp_uninstall.sh
	if [ $? -eq 0 ]; then
		return 0
	fi
	sleep 3
	
	((index=index+1))
done

if [ $index -eq 20 ]; then
	install_log "ERROR" "common_control" "Failed to invoke dsdp_uninstall.sh"
	return 1
fi

return 0






