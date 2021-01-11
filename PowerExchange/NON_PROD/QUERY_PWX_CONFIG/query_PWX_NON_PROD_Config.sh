#!/bin/bash
############################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Purpose: This Script will Provide the Query Result of PWX Instance configured in NON_PROD
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
###########################################################################################

source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 

INSTANCE=$1

grep -i "=${INSTANCE}:" ${CDC_PWX_CONFIG_FILE_NON_PROD} | grep -v grep > /dev/null
RET_CODE=$?
RECLINE=`grep -i "=${INSTANCE}:" ${CDC_PWX_CONFIG_FILE_NON_PROD} | grep -v grep`

### Check if entered publisher instance is configured in the system
if [ ${RET_CODE} -gt 0 ]
then
    echo -e "\n*** ERROR: ${INSTANCE} not configured in this server"
    echo "Exiting ..!"
    echo
    exit 1
fi

PWX_ERP_NAME=`echo ${RECLINE} | cut -d":" -f1 | cut -d"=" -f2`
PWX_DB=`echo ${RECLINE} | cut -d":" -f2 | cut -d"=" -f2`
DB=`echo ${RECLINE} | cut -d":" -f3 | cut -d"=" -f2`
PWX_USER=`echo ${RECLINE} | cut -d":" -f4 | cut -d"=" -f2`
PWX_SERVER=`echo ${RECLINE} | cut -d":" -f5 | cut -d"=" -f2`
MONITORING_ENABLED=`echo ${RECLINE} | cut -d":" -f6 | cut -d"=" -f2`
CONFIG_SCRIPT_ENABLED=`echo ${RECLINE} | cut -d":" -f7 | cut -d"=" -f2`
ACTIVITY_ENABLED=`echo ${RECLINE} | cut -d":" -f8 | cut -d"=" -f2`
TEMP_DISABLE=`echo ${RECLINE} | cut -d":" -f9 | cut -d"=" -f2`
ENV=`echo ${RECLINE} | cut -d":" -f10 | cut -d"=" -f2`
TIMESTAMP=`echo ${RECLINE} | cut -d":" -f11 | cut -d"=" -f2`
DL=`echo ${RECLINE} | cut -d":" -f12 | cut -d"=" -f2`
ASSIGNMENT=`echo ${RECLINE} | cut -d":" -f13 | cut -d"=" -f2`



echo "#################################################################################################################"
echo "-----------------------------------------------------------------------------------------------------------------"
ten="          "
five="     "
thirtyfive="$ten$ten$ten$five"
#awk 'BEGIN {s=sprintf("\t%96s","");gsub(/ /,"-",s);print s}'
echo -e "\t$thirtyfive PowerExchange ERP Configuration" 
awk 'BEGIN {s=sprintf("\t%97s","");gsub(/ /,"-",s);print s}'
echo -e "PWX_ERP_NAME:$PWX_ERP_NAME" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_DB:$PWX_DB" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "DB:$DB" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_USER:$PWX_USER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_SERVER:$PWX_SERVER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "MONITORING_ENABLED:$MONITORING_ENABLED" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "CONFIG_SCRIPT_ENABLED:$CONFIG_SCRIPT_ENABLED" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "ACTIVITY_ENABLED:$ACTIVITY_ENABLED" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "TEMP_DISABLE:$TEMP_DISABLE" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "ENV:$ENV" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "TIMESTAMP:$TIMESTAMP" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "DL:$DL" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "ASSIGNMENT GROUP:$ASSIGNMENT" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
awk 'BEGIN {s=sprintf("\t%97s","");gsub(/ /,"-",s);print s}'

#awk 'BEGIN {s=sprintf("\t%97s","");gsub(/ /,"-",s);print s}'
echo "-----------------------------------------------------------------------------------------------------------------"
echo "#################################################################################################################"
echo


# Return Value
export $PWX_ERP_NAME
