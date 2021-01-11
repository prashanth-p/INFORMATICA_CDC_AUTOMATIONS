#!/bin/bash
############################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Module: query_Pub_PWX_Details_CDL.sh
# Purpose: This Script will Provide the Query Result of PUB CDL Instance configured in Prod
# --------------------------------------------------------------------------------
# Usage:
#   * ./query_Pub_PWX_Details_CDL "INSTANCE_NAME"
#   ex: ./query_Pub_PWX_Details_CDL "JDE_BWIATLAS_CDL01_PROD"
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

PUB_INSTANCE=$1


grep "=${PUB_INSTANCE}:" ${CDC_PUB_CONFIG_FILE_CDL_PROD} | grep -v grep > /dev/null
RET_CODE=$?

### Check if entered publisher instance is configured in the system
if [ ${RET_CODE} -gt 0 ]
then
    echo -e "\n*** ERROR: Publisher instance : ${PUB_INSTANCE} not configured in this server"
    echo "Exiting ..!"
    echo
    exit 1
fi

echo -e "Fetching Details..! Please wait..!"
echo

RECLINE=`grep "=${PUB_INSTANCE}:" ${CDC_PUB_CONFIG_FILE_CDL_PROD} | grep -v grep`
instance=`echo ${RECLINE} | cut -d":" -f1 | cut -d"=" -f2`
PWX_ERP_NAME=`echo ${RECLINE} | cut -d":" -f2 | cut -d"=" -f2`
ENV=`echo ${RECLINE} | cut -d":" -f3 | cut -d"=" -f2`
LIVE=`echo ${RECLINE} | cut -d":" -f4 | cut -d"=" -f2`
KAFKA_ACTIVITY=`echo ${RECLINE} | cut -d":" -f5 | cut -d"=" -f2`
CONFIG_SCRIPT_ENABLED=`echo ${RECLINE} | cut -d":" -f6 | cut -d"=" -f2`
PUB_USER=`echo ${RECLINE} | cut -d":" -f7 | cut -d"=" -f2`
SERVER=`echo ${RECLINE} | cut -d":" -f8 | cut -d"=" -f2`


# Publisher Config Path
PWX_PUB_CONFIG=/apps/Informatica/PWX_CDC_Publisher/$instance/config/cdcPublisherPowerExchange.cfg
MONITOR_PUB_CONFIG=/apps/Scripts/monitor/monitor_pub_instances.cfg

SCRIPT="PWX_LIST=\$(echo \"\$(cat ${PWX_PUB_CONFIG} | grep -i \"Extract.pwxNodeLocation=\" | cut -d\"=\" -f2)\" 2> /dev/null);PWX_VER=\$(echo \"\$(cat ${MONITOR_PUB_CONFIG} | grep -i \"$instance\" | cut -d\":\" -f4)\" 2> /dev/null);PWX_HOME=\"/apps/Informatica/PowerExchange\$PWX_VER\";PWX_SERVER=\$(echo \"\$(cat \${PWX_HOME}/dbmover.cfg | grep -i \"\$PWX_LIST\" | cut -d\",\" -f3)\" 2> /dev/null);echo \"\$PWX_LIST|\$PWX_VER|\$PWX_SERVER\";"

PWX_SERVER_OUT=`ssh -q -o PasswordAuthentication=no -o ConnectTimeout=600 -n $PUB_USER@$SERVER $SCRIPT`

PWX_LISTENER=`echo $PWX_SERVER_OUT | cut -d"|" -f1`
PWX_VERSION=`echo $PWX_SERVER_OUT | cut -d"|" -f2`
PWX_SERVER=`echo $PWX_SERVER_OUT | cut -d"|" -f3`



echo "#################################################################################################################"
echo "-----------------------------------------------------------------------------------------------------------------"
ten="          "
five="     "
thirtyfive="$ten$ten$ten$five"
#awk 'BEGIN {s=sprintf("\t%96s","");gsub(/ /,"-",s);print s}'
echo -e "\t$thirtyfive CDC Publisher PROD - CDL Configuration" 
awk 'BEGIN {s=sprintf("\t%97s","");gsub(/ /,"-",s);print s}'
echo -e "instance:$instance" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_ERP_NAME:$PWX_ERP_NAME" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "ENV:$ENV" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "LIVE:$LIVE" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "KAFKA_ACTIVITY:$KAFKA_ACTIVITY" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "CONFIG_SCRIPT_ENABLED:$CONFIG_SCRIPT_ENABLED" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "Pub SSH UID:$PUB_USER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "CDL SERVER:$SERVER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_LISTENER:$PWX_LISTENER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_VERSION:$PWX_VERSION" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "PWX_SERVER:$PWX_SERVER" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "KAFKA TEAM DL:$KAFKA_DL" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
echo -e "KAFKA ASSIGNMENT GROUP:$KAFKA_ASSIGNMENT_GROUP" | awk -F':' '{ printf("\t| %-25s | %-60s\t|\n", $1, $2) }'
awk 'BEGIN {s=sprintf("\t%97s","");gsub(/ /,"-",s);print s}'
echo "-----------------------------------------------------------------------------------------------------------------"
echo "#################################################################################################################"
echo



# Return Variable
export $PWX_ERP_NAME
