#!/bin/bash
####################################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Purpose: This Script will Provide the Query Result of PUB NON_CDL Instance configured in Prod
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
    echo "Module : get_Pub_PWX_Details_NON_CDL.sh"
    echo "#############################################################"
    echo
}

clear
source $DISPLAY_PUB_NON_CDL_PROD_CONFIG_SCRIPT ""
export PUB_INSTANCE=$PUB_INSTANCE
echo -e "Fetching Details of $PUB_INSTANCE"
sleep 1


MODULE_HEADER
echo -e "Fetching Details of $PUB_INSTANCE"
sleep 1
clear
source $QUERY_PUB_NON_CDL_PROD_CONFIG_SCRIPT $PUB_INSTANCE
export PWX_ERP_NAME=$PWX_ERP_NAME
echo
source $QUERY_PWX_PROD_CONFIG_SCRIPT $PWX_ERP_NAME
