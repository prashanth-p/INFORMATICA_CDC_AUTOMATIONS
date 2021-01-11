#!/bin/bash
###########################################################################################
# Author: Prashanth Pradeep
# Created on: Sun Dec 13 10:16:58 EST 2020
# Purpose: This Script will update the kafka activity flag in NON_CDL Publisher Prod Config
# -----------------------------------------------------------------------------------------
# Version: 1.0.0
# -----------------------------------------------------------------------------------------
# Last Updated On: Sun Dec 13 10:16:58 EST 2020
# Last Updated By: 
# -------------
# Change Log:
# -------------
#   1.0.0   -   Created the Script 
#
############################################################################################



source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 


#################################################
# Driver Code                                   #
#################################################
main() {
      
    MODULE_HEADER
    echo -e "You have selected: Enable/disable Kafka Activity Tracker - Publisher NON_CDL Prod"
    echo
    echo -e "Are you sure you want to enable/disable Kafka Activity?"
    echo -e "Please Enter your choice(y/n): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
    sleep 1

    if [ "$QUERY_TYPE" == "Y" ]; then
        MODULE_HEADER
        echo
        echo -e "Proceeding with Enable/disable Kafka Activity..!"
        echo
        echo -e "Please enter your Email ID to proceed:"
        echo -e "Email ID: \c"
        read TEMP
        export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`
        export user_email_id=$QUERY_TYPE
        echo

        if [ `echo $QUERY_TYPE | grep -i @ITS.JNJ.COM` ]; then         
            
            echo -e "Select from the below options: "
            echo
            echo -e "\t1. Enable Kafka Activity Flag"
            echo
            echo -e "\t2. Disable Kafka Activity Flag"
            echo
            echo -e "Please Enter your choice(1/2): \c"
            read TEMP
            export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

            if [ "$QUERY_TYPE" == "1" ]; then
                echo 
                echo -e "You have Selected Option 1: Enable Kafka Activity Flag"
                sleep 1
                KAFKA_FLAG ENABLE
            elif [ "$QUERY_TYPE" == "2" ]; then
                echo 
                echo -e "You have Selected Option 2: Disable Kafka Activity Flag"
                sleep 1
                KAFKA_FLAG DISABLE
            else
                echo -e "*** You have selected an Invalid Option"
                echo -e "Exiting..!"
                echo
                exit 0
            fi
    
        else         
            echo -e "*** You have entered an invalid Email ID"
            echo -e "Exiting..!"
            echo
            exit 0    
        fi

            
    elif [ "$QUERY_TYPE" == "N" ]; then
            echo
            echo -e "*** User Not Proceding to Enable/Disable Kafka Activity Flag"
            echo -e "Exiting..!"
            echo
            exit 0      

        
    else
        echo
        echo -e "You have selected an Invalid Option"
        echo -e "Exiting..!"
        echo
        exit 0
    fi

}

#####################################################
# Main Methods                                      #
#####################################################
KAFKA_FLAG() {
    flag=$1
    export change=""
    export comments=""
    if [ "$1" == "ENABLE" ]; then
        updateFlag="KAFKA_ACTIVITY=1"
        MODULE_HEADER
        echo
        echo -e "1. Enter the CR/INC/SR Details:"
        echo -e "\t**(Enter NA if not available)**"
        echo -e "Please Enter your answer here: \c"
        read TEMP
        export change=`echo ${TEMP} | tr "a-z" "A-Z"`
        echo
        echo -e "1. Enter comments about the activity:"
        echo -e "Please Enter your answer here: \c"
        read TEMP
        export comments=`echo ${TEMP} | tr "a-z" "A-Z"`
        echo
        echo -e "Please select the region where we have the Kafka Activity: "
    elif [ "$1" == "DISABLE" ]; then
        updateFlag="KAFKA_ACTIVITY=0"
        MODULE_HEADER
        echo
        echo -e "1. Enter the details of the CR/SR/INC which is completed:"
        echo -e "\t**(Enter NA if not available)**"
        echo -e "Please Enter your answer here: \c"
        read TEMP
        export change=`echo ${TEMP} | tr "a-z" "A-Z"`
        echo
        echo
        echo -e "1. Enter comments before performing the disable activity:"
        echo -e "Please Enter your answer here: \c"
        read TEMP
        export comments=`echo ${TEMP} | tr "a-z" "A-Z"`
        echo
        echo
        echo -e "Please select the region where we have to disable the Kafka Activity Flag:"
    else
        INVALID_OPTION
    fi
    
    echo
    echo -e "\t1. NA Prod Region"
    echo
    echo -e "\t2. EMEA Prod Region"
    echo
    echo -e "\t3. ASPAC Prod Region"
    echo
    echo -e "Please Enter your choice(1/2/3): \c"
    read TEMP
    export QUERY_TYPE=`echo ${TEMP} | tr "a-z" "A-Z"`

  

    if [ "$QUERY_TYPE" == "1" ];then
        region="NA_PROD"
        $ALERT_EMAILS_KAFKA_ACTIVITY_NON_CDL_SCRIPT_API "$region" "$updateFlag" "$user_email_id" "$change" "$comments"
      
    elif [ "$QUERY_TYPE" == "2" ];then
        region="EMEA_PROD"
        $ALERT_EMAILS_KAFKA_ACTIVITY_NON_CDL_SCRIPT_API "$region" "$updateFlag" "$user_email_id" "$change" "$comments"
        
    elif [ "$QUERY_TYPE" == "3" ];then
        region="ASPAC_PROD"
        $ALERT_EMAILS_KAFKA_ACTIVITY_NON_CDL_SCRIPT_API "$region" "$updateFlag" "$user_email_id" "$change" "$comments"
    else
        echo "***Invalid option..!"
        echo "Exiting ...!"
        exit 0
    fi
        
}



############################################################################
# Visual Methods
############################################################################
MODULE_HEADER() {
    clear
    echo
    echo "#############################################################"
    echo "Module : update_kafka_activity.sh"
    echo "#############################################################"
    echo
}


#####################################################
# Logging Method                                    #
#####################################################

timestamp() {
    echo -e "$(date '+%d-%b-%Y %H:%M:%S') EST"
}

diffTimestamp() {
    echo -e "$(date +"%y%m%d")"
}

printstar() {
    echo -e "********************************************************************"
}

INVALID_OPTION() {
    echo -e "*** Invalid Option..!"
    echo -e "Exiting..!"
    exit 0
}



main "$@"


