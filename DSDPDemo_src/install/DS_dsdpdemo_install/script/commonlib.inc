#!/usr/bin/ksh

################################################################################
# Name       : commonlib.inc
# Describe   : common shell library for developers.
# Date       : 2008-10-18
# Functions  :
#              null
################################################################################

# test environment variable INSTALL_TASK_DIR
if [ "X${INSTALL_TASK_DIR}" = "X" ]; then
	# include by integrated script(in top level)
	export INSTALL_TASK_DIR=`(cd ..; pwd)`
	# control install progress of components
	export PROGRESS_MIN=0
	export PROGRESS_MAX=100
	# grant read/write privilege to every file and dir in ${INSTALL_TASK_DIR}
	if [ "X`whoami`" = "Xroot" ]; then
		(chmod 777 "${INSTALL_TASK_DIR}")
		(cd "${INSTALL_TASK_DIR}"; find ./ -type d |xargs chmod 777)
		(cd "${INSTALL_TASK_DIR}"; find ./ ! -type d |xargs chmod u+r,u+w,g+r,g+w,o+r,o+w)
	fi
fi

# include ideploy common shell lib
typeset CUR_DIR=`pwd`
cd ${INSTALL_TASK_DIR}/script
. ./ideploy.inc
. ./commonfunc.lib
. ./err.inc
. ./user.inc
. ./logutil.lib
. ./host_info.lib
. ./configfileutil.lib
cd "${CUR_DIR}"

# disable ASSERT in ideploy
BRZ_DEBUG=0

# set PERL module search path
export PERLLIB="${IDEPLOY_PKG_PATH}/tools"
export PERL5LIB="${IDEPLOY_PKG_PATH}/tools"

# global temp directory
TMP="${IDEPLOY_PKG_PATH}/tmp"

# tasknum
TASK_NUM=`echo "${IDEPLOY_PKG_PATH}" |awk -F/ '{ i = NF-1; print $i; }'`

# create if it dosen't exist
if [ ! -d "${TMP}" ]; then
	mkdir -p "${TMP}"
	chmod 777 "${TMP}"
fi

# redefine ideploy black hole device
if [ "X${IDEPLOY_NULL}" = "X" ]; then
	IDEPLOY_NULL="${TMP}/.ideploy_null"
fi

typeset current_user=`whoami`
typeset is_ideploy_null_mine=`find "${IDEPLOY_NULL}" -user "${current_user}" | wc -l | sed "s/[ \t]//g"`
if [ -f "${IDEPLOY_NULL}" -a ${is_ideploy_null_mine} -eq 1 ]; then
	chmod 666 "${IDEPLOY_NULL}"
fi

if [ ! -f "${IDEPLOY_NULL}" ]; then
	touch "${IDEPLOY_NULL}"
	chmod 666 "${IDEPLOY_NULL}"
fi

# install perl module XML if not installed
if [ ! -d "${IDEPLOY_PKG_PATH}/tools/XML" ]; then
	if [ ! -f "${IDEPLOY_PKG_PATH}/script/XML.tar" ]; then
		log_echo error "perl module XML.tar doesn't exist."
		exit 1
	fi
	
	if [ ! -d "${IDEPLOY_PKG_PATH}/tools" ]; then
		mkdir -p "${IDEPLOY_PKG_PATH}/tools"
	fi 
	
	cp "${IDEPLOY_PKG_PATH}/script/XML.tar" "${IDEPLOY_PKG_PATH}/tools/" > "${IDEPLOY_NULL}" 2>&1
	(cd "${IDEPLOY_PKG_PATH}/tools"; tar xf XML.tar) > "${IDEPLOY_NULL}" 2>&1
	if [ $? -ne 0 ]; then
		log_echo error "Installing perl module XML.tar failed."
		exit 1
	fi
	rm "${IDEPLOY_PKG_PATH}/tools/XML.tar" > "${IDEPLOY_NULL}" 2>&1
fi


