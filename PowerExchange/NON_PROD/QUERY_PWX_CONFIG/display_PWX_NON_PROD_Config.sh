#!/bin/bash
#######################################$$$$$$$$$$$$$$$###########################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Module : display_PWX_NON_PROD_Config.sh
# Purpose: This Script will display the PWX Config file and return the instance selected
# Return Value: Instance value selected
# --------------------------------------------------------------------------------
# Usage:
#   * ./display_PWX_NON_PROD_Config.sh
#   * ./display_PWX_NON_PROD_Config.sh "LIVE"
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
######################################################$$$$$$$$$$$$$#############################



source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 

MODULE_HEADER() {
    clear
    echo
    echo "#############################################################"
    echo "Module : display_PWX_NON_PROD_Config.sh"
    echo "#############################################################"
    echo
}

grepFlag=$1
if [ -z "$grepFlag" ]; then
     grepFlag="grep CONFIG_SCRIPT_ENABLED=1"
elif [ $grepFlag == "LIVE" ]; then
    grepFlag="grep MONITORING_ENABLED=1"
fi

MODULE_HEADER
echo -e "Welcome to the PWX Configuration Query Tool - NON_PROD"
echo
echo -e "Please select how you want query:"
echo -e "\t1. By ERP Name"
echo -e "\t2. By ERP DB Name"
echo -e "\t3. By ERP SERVER"

echo
echo -e "Please Enter your choice(1/2/3): \c"
read TEMP
QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

if [ "$QUERY_TYPE" == "1" ]; then
    echo "-------------------------------------------------------------"
    echo -e "You have selected Option 1: Query By ERP Name"
    echo "-------------------------------------------------------------"
    getInstanceBy="PWX_ERP"
    optionFlag=1
    sleep 2

elif [ "$QUERY_TYPE" == "2" ]; then
    echo "-------------------------------------------------------------"
    echo -e "You have selected Option 2: Query By DB Name"
    echo "-------------------------------------------------------------"
    getInstanceBy="PWX_DB"
    optionFlag=2
    sleep 2

elif [ "$QUERY_TYPE" == "3" ]; then
    echo "-------------------------------------------------------------"
    echo -e "You have selected Option 3: Query By ERP Server"
    echo "-------------------------------------------------------------"
    getInstanceBy="PWX_SERVER"
    optionFlag=5
    sleep 2
else
    echo 
    echo "Invalid option"
    echo "Exiting ..!"
    exit 1
fi


MODULE_HEADER
echo "Configured $getInstanceBy Instances:"
echo "-----------------------------------------------------------------------------------------------------------------"
NA_NON_PROD=`cat ${CDC_PWX_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=NA_NON_PROD" | cut -d":" -f$optionFlag | cut -d"=" -f2`
EMEA_NON_PROD=`cat ${CDC_PWX_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=EMEA_NON_PROD" | cut -d":" -f$optionFlag | cut -d"=" -f2`
ASPAC_NON_PROD=`cat ${CDC_PWX_CONFIG_FILE_NON_PROD} | $grepFlag | grep "ENV=ASPAC_NON_PROD" | cut -d":" -f$optionFlag | cut -d"=" -f2`


paste <(echo "NA") <(echo "EMEA") <(echo "ASPAC") | awk -F'\t' '{ printf("%-40s %-40s %s\n", $1, $2, $3) }'
echo "-----------------------------------------------------------------------------------------------------------------"
paste <(echo "$NA_NON_PROD") <(echo "$EMEA_NON_PROD") <(echo "$ASPAC_NON_PROD") | awk -F'\t' '{ printf("%-40s %-40s %s\n", $1, $2, $3) }'

echo "#################################################################################################################"
echo -e "Enter the $getInstanceBy Instance for the configuration details : \c"
read TEMP_PUB
INSTANCE=`echo ${TEMP_PUB} | tr "a-z" "A-Z"`
INSTANCE=`cat ${CDC_PWX_CONFIG_FILE_NON_PROD} | grep -i "$INSTANCE" | cut -d":" -f1 | cut -d"=" -f2`
export $INSTANCE
