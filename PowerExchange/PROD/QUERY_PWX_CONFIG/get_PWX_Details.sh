#!/bin/bash
##################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Purpose: This Script will get the details of PWX Instance configured in Prod
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
###################################################################################



source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 


############################################################################
# Visual Methods
############################################################################
MODULE_HEADER() {
    clear
    echo
    echo "#############################################################"
    echo "Module : get_PWX_Details.sh"
    echo "#############################################################"
    echo
}

############################################################################
# Methods
############################################################################
FETCH_PWX_DETAILS() {
    clear
    source $DISPLAY_PWX_PROD_CONFIG_SCRIPT
    # $DISPLAY_PWX_PROD_CONFIG_SCRIPT this script returns an instance
    INSTANCE=$INSTANCE
    clear
    MODULE_HEADER
    echo -e "Fetching Details of $INSTANCE"
    sleep 1
    echo
    # $QUERY_PWX_PROD_CONFIG_SCRIPT this script returns an PWX_ERP_NAME
    source $QUERY_PWX_PROD_CONFIG_SCRIPT $INSTANCE
    #echo $PWX_ERP_NAME
}


FETCH_PWX_DETAILS_AND_CDL() {
    FETCH_PWX_DETAILS
    export PWX_ERP_NAME=$PWX_ERP_NAME
    #echo $PWX_ERP_NAME
   $QUERY_PUB_CDL_PROD_CONFIG_SCRIPT $PWX_ERP_NAME
    
}
FETCH_PWX_DETAILS_AND_NON_CDL() {
    FETCH_PWX_DETAILS
    export PWX_ERP_NAME=$PWX_ERP_NAME
    #echo $PWX_ERP_NAME
   $QUERY_PUB_NON_CDL_PROD_CONFIG_SCRIPT $PWX_ERP_NAME
    
}
FETCH_PWX_DETAILS_AND_BOTH_CDL_NON_CDL() {
    FETCH_PWX_DETAILS
    export PWX_ERP_NAME=$PWX_ERP_NAME
    #echo $PWX_ERP_NAME
   $QUERY_PUB_CDL_PROD_CONFIG_SCRIPT $PWX_ERP_NAME
   $QUERY_PUB_NON_CDL_PROD_CONFIG_SCRIPT $PWX_ERP_NAME
    
}

MODULE_HEADER
echo -e "Welcome to Informatica CDC PowerExchange Query Tool - PROD..!"
echo
echo -e "Do you also want to fetch the corresponding Publisher Details?"
echo
echo -e "Please Enter your choice(y/n): \c"
read TEMP
export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

if [ "$QUERY_TYPE" == "Y" ]; then
    echo
    echo -e "Select from the below options: "
    echo
    echo
    echo -e "\t1. Fetch only CDL Publisher Details."
    echo
    echo -e "\t2. Fetch only NON-CDL Publisher Details."
    echo
    echo -e "\t3. Fetch both CDL and Non-CDL Details."
    echo
    echo -e "Please Enter your choice(1/2/3): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: Fetch only CDL Publisher Details."
        sleep 1
        FETCH_PWX_DETAILS_AND_CDL
        

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 2: Fetch only CDL Publisher Details."
        sleep 1
        FETCH_PWX_DETAILS_AND_NON_CDL
        
    elif [ "$QUERY_TYPE" == "3" ]; then
        echo 
        echo -e "You have Selected Option 3: Fetch both CDL and Non-CDL Details"
        sleep 1
        FETCH_PWX_DETAILS_AND_BOTH_CDL_NON_CDL
        
    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
    
elif [ "$QUERY_TYPE" == "N" ]; then
    echo
    echo -e "You Have Selected Option n: Fetch Only PWX ERP Details"
    echo
    echo -e "Fetching PWX ERP Details..! Please Wait..!"
    sleep 1
    FETCH_PWX_DETAILS

    
else
    echo -e "You have selected an Invalid Option"
    echo -e "Exiting..!"
    echo
    exit 0
fi

