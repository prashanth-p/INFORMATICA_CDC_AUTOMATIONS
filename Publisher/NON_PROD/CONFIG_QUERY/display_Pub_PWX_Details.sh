#!/bin/bash
####################################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Module : display_Pub_PWX_Details.sh
# Purpose: This Script will Provide the Query Result of PUB  Instance configured in NON_PROD
# --------------------------------------------------------------------------------
# Usage:
#   * ./display_Pub_PWX_Details.sh 
#   * ./display_Pub_PWX_Details.sh "LIVE"
# --------------------------------------------------------------------------------
# Version: 1.0.0
# --------------------------------------------------------------------------------
# Last Updated On: Thu Dec 10 10:36:31 EST 2020
# Last Updated By: 
# -------------
# Change Log:
# -------------
#   1.0.0   -   Created the Script 
#
###################################################################################################

source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 


############################################################################
# Visual Methods
############################################################################
MODULE_HEADER() {
    clear
    echo
    echo "#############################################################"
    echo "Module : display_Pub_PWX_Details.sh"
    echo "#############################################################"
    echo
}

grepFlag=$1
if [ -z "$grepFlag" ]; then
     grepFlag="grep CONFIG_SCRIPT_ENABLED=1"
elif [ $grepFlag == "LIVE" ]; then
    grepFlag="grep LIVE=1"
fi

MODULE_HEADER
echo "Configured Publisher Instances:"
echo "-----------------------------------------------------------------------------------------------"
NA_NON_PROD=`cat ${CDC_PUB_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=NA_NON_PROD" | cut -d":" -f1 | cut -d"=" -f2`
EMEA_NON_PROD=`cat ${CDC_PUB_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=EMEA_NON_PROD" | cut -d":" -f1 | cut -d"=" -f2`
ASPAC_NON_PROD=`cat ${CDC_PUB_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=ASPAC_NON_PROD" | cut -d":" -f1 | cut -d"=" -f2`

paste <(echo "NA") <(echo "EMEA") <(echo "ASPAC") | awk -F'\t' '{ printf("%-30s %-30s %s\n", $1, $2, $3) }'
echo "-----------------------------------------------------------------------------------------------"
paste <(echo "$NA_NON_PROD") <(echo "$EMEA_NON_PROD") <(echo "$ASPAC_NON_PROD") | awk -F'\t' '{ printf("%-30s %-30s %s\n", $1, $2, $3) }'

echo "#################################################"
echo -e "Enter the Publisher Instance for the configuration details : \c"
read TEMP_PUB
PUB_INSTANCE=`echo ${TEMP_PUB} | tr "a-z" "A-Z"`

export $PUB_INSTANCE