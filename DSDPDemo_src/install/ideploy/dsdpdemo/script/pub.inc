##!/usr/bin/ksh

################################################################################
# Name       : pub.inc
# Describe   : header file of shell library for component script developers.
# Date       : 2008-11-20
# Functions  :
#              null
################################################################################

if [ "X${INSTALL_TASK_DIR}" = "X" ]; then
	echo "Error: INSTALL_TASK_DIR should be specified before install."
	exit 1
fi

if [ ! -f "${INSTALL_TASK_DIR}/script/commonlib.inc" ]; then
	echo "Error: commonlib.inc doesn't exist."
	exit 1
fi

. ${INSTALL_TASK_DIR}/script/commonlib.inc
