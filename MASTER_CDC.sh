#!/bin/bash
##################################################################################
# Author: Prashanth Pradeep
# Created on: Thu Dec 10 10:36:31 EST 2020
# Purpose: This is a master control script for all the CDC Scripts
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

# ENVIRONMENT VARIABLES


source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 

#################################################
# Driver Code                                   #
#################################################
main() {
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica CDC Master Control Script:"
    echo
    echo -e "Please select between CDC PowerExchange and Publisher:"
    echo
    echo -e "\t1. Publisher"
    echo
    echo -e "\t2. PowerExchange"
    echo
    echo -e "Please Enter your choice(1/2): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: Publisher"
        sleep 1
        GOTO_PUBLISHER_CONTROL_FUNCTION
    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 1: PowerExchange"
        sleep 1
        GOTO_PWX_CONTROL_FUNCTION
    else
        echo
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}

#################################################
# Main Methods                                  #
#################################################

GOTO_PWX_CONTROL_FUNCTION() {
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica PowerExchange CDC Master Control..!"
    echo
    echo -e "Please select the Envirionment:"
    echo
    echo -e "\t1. NON_PROD"
    echo
    echo -e "\t2. Prod"
    echo
    echo -e "Please Enter your choice(1/2): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 2: NON_PROD"
        sleep 1
        GOTO_PWX_CONTROL_MASTER_FUNCTION "NON_PROD"

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 3: PROD"
        sleep 1
        GOTO_PWX_CONTROL_MASTER_FUNCTION "PROD"

    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}

GOTO_PUBLISHER_CONTROL_FUNCTION() {
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica CDC Publisher Master Control..!"
    echo
    echo -e "Please select the Envirionment:"
    echo
    echo -e "\t1. NON_PROD"
    echo
    echo -e "\t2. Prod"
    echo
    echo -e "Please Enter your choice(1/2): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: NON_PROD"
        sleep 1
        GOTO_PUBLISHER_CONTROL_FUNCTION_NON_PROD
    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 1: PROD"
        sleep 1
        GOTO_PUBLISHER_CONTROL_FUNCTION_PROD
    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}


######################################################################
# Sub Main Methods - PowerExchange
######################################################################
GOTO_PWX_CONTROL_MASTER_FUNCTION() {
    ENV=$1

    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica PowerExchange CDC - $ENV Master Control..!"
    echo
    echo -e "Please select Your Option:"
    echo
    echo -e "\t1. Get PWX $ENV ERP Details"
    echo
    echo -e "\t2. Permanently Enable/Disable PWX $ENV Monitoring"
    echo
    echo -e "\t3. Enable/Disable PWX $ENV Planned Activity Flag"
    echo
    echo -e "\t4. Temporary Enable/Disable PWX $ENV Monitoring"
    echo
    echo -e "\t5. Run the PowerExchnage CDC Adhoc $ENV Report"
    echo
    echo -e "Please Enter your choice(1/2/3/4/5): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: Get PWX $ENV ERP Details"
        sleep 1
        $CDC_PWX_HOME/$ENV/QUERY_PWX_CONFIG/get_PWX_Details.sh

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 2: Enable/Disable PWX $ENV Monitoring"
        sleep 1
        $CDC_PWX_HOME/$ENV/ENABLE_DISABLE_MONITORING/enable_disable_monitoring.sh

        
    elif [ "$QUERY_TYPE" == "3" ]; then
        echo 
        echo -e "You have Selected Option 3: Enable/Disable PWX $ENV Activity Flag"
        sleep 1
        $CDC_PWX_HOME/$ENV/Planned_Activity/planned_activity.sh
    elif [ "$QUERY_TYPE" == "4" ]; then
        echo 
        echo -e "You have Selected Option 4: Enable/Disable PWX $ENV Temp Disable Monitoring"
        sleep 1
        $CDC_PWX_HOME/$ENV/Temp_Enable_Disable/temp_enable_disable.sh
        
    elif [ "$QUERY_TYPE" == "5" ]; then
        echo 
        echo -e "You have Selected Option 5: Run the PowerExchnage CDC Adhoc $ENV Report"
        sleep 1
        $CDC_PWX_HOME/$ENV/PWX_REPORT/pwx_report.sh 
    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}


GOTO_PUBLISHER_CONTROL_FUNCTION_NON_PROD() {
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica CDC Publisher - NON_PROD Master Control..!"
    echo
    echo -e "Please select Your Option:"
    echo
    echo -e "\t1. Get NON_PROD Publisher Instance Details"
    echo
    echo -e "\t2. Permanently Enable/Disable Publisher Report Monitoring - NON_PROD"
    echo
    echo -e "\t3. Enable/Disable Kafka Planned Activity Flag"
    echo
    echo -e "\t4. Run the Publisher CDC Adhoc NON_PROD Report"
    echo
    echo -e "Please Enter your choice(1/2/3/4): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: Get NON_PROD Publisher Instance Details"
        sleep 1
        $CDC_PUB_HOME_NON_PROD/CONFIG_QUERY/get_Pub_PWX_Details.sh

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 2: Permanently Enable/Disable Publisher Report Monitoring - NON_PROD" 
        sleep 1
        $CDC_PUB_HOME_NON_PROD/ENABLE_DISABLE_MONITORING/enable_disable_monitoring.sh

        
    elif [ "$QUERY_TYPE" == "3" ]; then
        echo 
        echo -e "You have Selected Option 3: Enable/Disable Kafka Planned Activity Flag"
        sleep 1
        $CDC_PUB_HOME_NON_PROD/KAFKA_ACTIVITY_FLAG_SCRIPT/update_kafka_activity.sh
 
    elif [ "$QUERY_TYPE" == "4" ]; then
        echo 
        echo -e "You have Selected Option 4: Run the Publisher CDC Adhoc NON_PROD Report"
        sleep 1
        $CDC_PUB_HOME_NON_PROD/PUB_REPORT/pub_report.sh

    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}

GOTO_PUBLISHER_CONTROL_FUNCTION_PROD() {
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica CDC Publisher - PROD Master Control..!"
    echo
    echo -e "Please select Your Option:"
    echo
    echo -e "\t1. CDL"
    echo
    echo -e "\t2. NON CDL"
    echo
    
    echo -e "Please Enter your choice(1/2): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        ENV=CDL
        echo -e "You have Selected Option 1: Publisher Prod - $ENV"
        sleep 1
        GOTO_PUBLISHER_CONTROL_FUNCTION_PROD_MASTER $ENV

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        ENV=NON_CDL
        echo -e "You have Selected Option 2: Publisher Prod - $ENV"
        sleep 1
        GOTO_PUBLISHER_CONTROL_FUNCTION_PROD_MASTER $ENV
        
    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}

GOTO_PUBLISHER_CONTROL_FUNCTION_PROD_MASTER() {
    ENV=$1
    MASTER_CDC_HEADER
    echo -e "Welcome to Informatica CDC Publisher - PROD - $ENV Master Control..!"
    echo
    echo -e "Please select Your Option:"
    echo
    echo -e "\t1. Get PROD - $ENV Publisher Instance Details"
    echo
    echo -e "\t2. Permanently Enable/Disable Publisher Report Monitoring - PROD - $ENV"
    echo
    echo -e "\t3. Enable/Disable Kafka Planned Activity Flag"
    echo
    echo -e "\t4. Run the Publisher CDC Adhoc PROD - $ENV Report"
    echo
    echo -e "Please Enter your choice(1/2/3/4): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    if [ "$QUERY_TYPE" == "1" ]; then
        echo 
        echo -e "You have Selected Option 1: Get PROD - $ENV Publisher Instance Details"
        sleep 1
        fileName=`echo "CDC_PUB_HOME_PROD_"$ENV"_GET_CONFIG_SCRIPT"`
        source ${!fileName}
        

    elif [ "$QUERY_TYPE" == "2" ]; then
        echo 
        echo -e "You have Selected Option 2: Permanently Enable/Disable Publisher Report Monitoring - PROD - $ENV"
        sleep 1
        . ${CDC_PUB_HOME_PROD}/${ENV}/ENABLE_DISABLE_MONITORING/enable_disable_monitoring.sh
        
    elif [ "$QUERY_TYPE" == "3" ]; then
        echo 
        echo -e "You have Selected Option 3: Enable/Disable Kafka Planned Activity Flag"
        fileName=`echo "ALERT_EMAILS_KAFKA_ACTIVITY_"$ENV"_SCRIPT"`
        . ${CDC_PUB_HOME_PROD}/${ENV}/KAFKA_ACTIVITY_FLAG_SCRIPT/update_kafka_activity.sh
        sleep 1
        
    elif [ "$QUERY_TYPE" == "4" ]; then
        echo 
        echo -e "You have Selected Option 4: Run the Publisher CDC Adhoc PROD - $ENV Report"
        ${CDC_PUB_HOME_PROD}/${ENV}/PUB_REPORT/pub_report.sh
        sleep 1
    
    else
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi
}

############################################################################
# Visual Methods
############################################################################
MASTER_CDC_HEADER() {
    clear
    echo
    echo "#############################################################"
    echo "Module : MASTER_CDC.sh"
    echo "#############################################################"
    echo
}


#####################################################
# Logging Method                                    #
#####################################################

timestamp() {
    echo -e "$(date '+%d-%b-%Y %H:%M:%S') EST"
}

printstar() {
    echo -e "********************************************************************"
}

main "$@"
