#!/bin/bash
####################################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Module : display_Pub_PWX_Details_CDL.sh
# Purpose: This Script will Provide the Query Result of PUB CDL Instance configured in Prod
# --------------------------------------------------------------------------------
# Usage:
#   * ./display_Pub_PWX_Details_CDL.sh 
#   * ./display_Pub_PWX_Details_CDL.sh "LIVE"
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
    echo "Module : display_Pub_PWX_Details_CDL.sh"
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
NA_PROD=`cat ${CDC_PUB_CONFIG_FILE_CDL_PROD} | $grepFlag | grep "ENV=NA_PROD" | cut -d":" -f1 | cut -d"=" -f2`
EMEA_PROD=`cat ${CDC_PUB_CONFIG_FILE_CDL_PROD} | $grepFlag | grep "ENV=EMEA_PROD" | cut -d":" -f1 | cut -d"=" -f2`
ASPAC_PROD=`cat ${CDC_PUB_CONFIG_FILE_CDL_PROD} | $grepFlag | grep "ENV=ASPAC_PROD" | cut -d":" -f1 | cut -d"=" -f2`

#echo $NA_PROD
#echo
#echo $EMEA_PROD
#echo
#echo $ASPAC_PROD

paste <(echo "NA") <(echo "EMEA") <(echo "ASPAC") | awk -F'\t' '{ printf("%-30s %-30s %s\n", $1, $2, $3) }'
echo "-----------------------------------------------------------------------------------------------"
paste <(echo "$NA_PROD") <(echo "$EMEA_PROD") <(echo "$ASPAC_PROD") | awk -F'\t' '{ printf("%-30s %-30s %s\n", $1, $2, $3) }'

echo "#################################################"
echo -e "Enter the Publisher Instance for the configuration details : \c"
read TEMP_PUB
PUB_INSTANCE=`echo ${TEMP_PUB} | tr "a-z" "A-Z"`

export $PUB_INSTANCE
