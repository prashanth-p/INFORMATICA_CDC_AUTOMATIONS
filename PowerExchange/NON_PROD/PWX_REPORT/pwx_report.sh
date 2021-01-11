#!/bin/bash
##################################################################################
# Author: Prashanth
# Created on: Thu Nov 12 12:45:26 EST 2020
# Purpose: To Generate Publisher LAG Report
# --------------------------------------------------------------------------------
# Version: 1.0.0
# --------------------------------------------------------------------------------
# Last Updated On: Thu Nov 12 12:45:26 EST 2020
# Last Updated By: Prashanth Pradeep
# -------------
# Change Log:
# -------------
#           - Completed the script and looped DL
#
###################################################################################

# Global Variable Definition
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_ENV_VAR.cfg 
source /apps/Admin_Scripts/INFORMATICA_CDC_AUTOMATIONS/MASTER_CONFIG/CDC_AUTOMATIONS_EMAIL_VAR.cfg 

####################################################
# Temp Variables created for the script
####################################################
export tempDir=$(mktemp -d $CDC_PWX_HOME_NON_PROD_TEMPDIR/temp.XXXXXXXXXX)
export NA_NON_PROD=$(mktemp -d $tempDir/NA_NON_PROD.XXXXXXXXXX)
export EMEA_NON_PROD=$(mktemp -d $tempDir/EMEA_NON_PROD.XXXXXXXXXX)
export ASPAC_NON_PROD=$(mktemp -d $tempDir/ASPAC_NON_PROD.XXXXXXXXXX)
export NA_COUNT=0
export EMEA_COUNT=0
export ASPAC_COUNT=0
export ALERT_EMAIL_FILE=${ALERT_EMAILS_PWX_REPORT_NON_PROD}/ALERT_EMAIL_FILE_$(date +"%d%b%Y_%H%M%S").html
export subjectERPUnavailable=""
export subjectERPIssue=""
export subjectLoggerDown=""
export subListenerDown=""
export subERPMaintenance=""

####################################################
# Ensure safe cleanup of temp files after we exit
####################################################
trap ON_EXIT_SAFE_CLEANUP EXIT

main() {
    get_config_file_data
    get_max_count_of_three_regions_to_set_table_size $NA_COUNT $EMEA_COUNT $ASPAC_COUNT
    tableCount=$greatest
    write_data_to_html_file $tableCount
    SEND_EMAIL_TO_TEAM
}

get_config_file_data() {
    while IFS= read -r RECLINE
    do

        if [[ ${RECLINE} != *"MONITORING_ENABLED=1"* ]];then
             continue
        fi

        pwx_logger_fail_flag="false"
        pwx_listener_fail_flag="false"

        export PWX_ERP_NAME=`echo $RECLINE | cut -d":" -f1 | cut -d"=" -f2`
        export PWX_DB_NAME=`echo $RECLINE | cut -d":" -f2 | cut -d"=" -f2`
        export PWX_SERVER=`echo $RECLINE | cut -d":" -f5 | cut -d"=" -f2`
        export PWX_USER=`echo $RECLINE | cut -d":" -f4 | cut -d"=" -f2`
        export ENV=`echo $RECLINE | cut -d":" -f10 | cut -d"=" -f2`
        export MONITORING_ENABLED=`echo $RECLINE | cut -d":" -f6 | cut -d"=" -f2`
        export PWX_ERP_ACTIVITY=`echo $RECLINE | cut -d":" -f8 | cut -d"=" -f2`
        export PWX_TEMP_DISABLE=`echo $RECLINE | cut -d":" -f9 | cut -d"=" -f2`
        

        printstar
        echo -e "$(timestamp):\tProcessing $PWX_ERP_NAME"
        echo -e "$(timestamp):\tENV: $ENV"
        echo -e "$(timestamp):\tLIVE: $MONITORING_ENABLED"
        echo -e "$(timestamp):\tPWX_ERP_NAME: $PWX_ERP_NAME"
        echo -e "$(timestamp):\tPWX_TEMP_DISABLE: $PWX_TEMP_DISABLE"
        echo -e "$(timestamp):\tPWX_ERP_ACTIVITY: $PWX_ERP_ACTIVITY"
        echo -e "$(timestamp):\tPWX_USER: $PWX_USER"
        echo -e "$(timestamp):\tPWX_SERVER: $PWX_SERVER"
        echo -e "$(timestamp):\tPWX_DB_NAME: $PWX_DB_NAME"

    
        if [ "$ENV" == "NA_NON_PROD" ]; then
            export NA_COUNT=$((NA_COUNT+1))
            export instanceDir=$(mktemp -d ${NA_NON_PROD}/${NA_COUNT}.XXXXXXXXXX)       
        elif [ "$ENV" == "EMEA_NON_PROD" ]; then
            export EMEA_COUNT=$((EMEA_COUNT+1))
            export instanceDir=$(mktemp -d ${EMEA_NON_PROD}/${EMEA_COUNT}.XXXXXXXXXX)
        elif [ "$ENV" == "ASPAC_NON_PROD" ]; then
            export ASPAC_COUNT=$((ASPAC_COUNT+1))
            export instanceDir=$(mktemp -d ${ASPAC_NON_PROD}/${ASPAC_COUNT}.XXXXXXXXXX)
        fi

        
        export SSH_SCRIPT="LOGGER_STATUS=\$(ps -ef | grep pwxccl | grep -v grep | wc -l);LISTENER_STATUS=\$(ps -ef | grep dtl | grep -v grep | wc -l);echo \"\$LOGGER_STATUS|\$LISTENER_STATUS\";"

        export SSH_RESULT=`ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=600 -n $PWX_USER@$PWX_SERVER $SSH_SCRIPT`

        if [ -z "$SSH_RESULT" ]; then
            if [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                result="<td style=\"font-size:0.60em;\">$PWX_ERP_NAME</td><td style=\"font-size:0.60em;\">$PWX_DB_NAME</td><td style=\"font-size:0.60em;\">$PWX_SERVER</td><td style=\"font-size:0.60em;\" bgcolor=\"$erpMaintenanceColor\">ERPMaintenance</br>NA</td><td style=\"font-size:0.60em;\" bgcolor=\"$erpMaintenanceColor\">ERPMaintenance</br>NA</td>"
                export subERPMaintenance="{ERP Activity}"

            elif [ $PWX_TEMP_DISABLE -eq 1 ]; then
                result="<td style=\"font-size:0.60em;\">$PWX_ERP_NAME</td><td style=\"font-size:0.60em;\">$PWX_DB_NAME</td><td style=\"font-size:0.60em;\">$PWX_SERVER</td><td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">TempDisabled</br>NA</td><td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">TempDisabled</br>NA</td>"
                export subjectERPIssue="{ERP Mon Temp Disabled}"

            else
                result="<td style=\"font-size:0.60em;\">$PWX_ERP_NAME</td><td style=\"font-size:0.60em;\">$PWX_DB_NAME</td><td style=\"font-size:0.60em;\">$PWX_SERVER</td><td style=\"font-size:0.60em;\" bgcolor=\"$pwxDownColor\">NA</td><td style=\"font-size:0.60em;\" bgcolor=\"$pwxDownColor\">NA</td>"
            
            fi

            echo $result > $instanceDir/result
            echo $result
            subjectERPUnavailable="{ERP Connectivity Issue}"
            continue
        fi
    
        instanceResult="<td style=\"font-size:0.60em;\">$PWX_ERP_NAME</td>"
        dbResult="<td style=\"font-size:0.60em;\">$PWX_DB_NAME</td>"
        serverResult="<td style=\"font-size:0.60em;\">$PWX_SERVER</td>"

        
        logger_status=`echo $SSH_RESULT | cut -d"|" -f1`
        listener_status=`echo $SSH_RESULT | cut -d"|" -f2`
        
        ##################################################        
        # If Logger is running
        ##################################################
        
        if [[ $logger_status -gt 0 ]]; then
               if [ $PWX_TEMP_DISABLE -eq 1 ]; then
                    status="LogRunning</br>TempDisabled"
                    loggerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">$status</td>"
                    export subjectERPIssue="{ERP Mon Temp Disabled}"
                elif [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="LogRunning</br>ERP Activity"
                    loggerResult="<td style=\"font-size:0.60em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subERPMaintenance="{ERP Activity}"
                else
                    status="Live"
                    loggerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$allGoodPwxColor\">$status</td>"
                fi 
        # If Logger is not running
        else
            subjectLoggerDown="**{Logger Down}**"
            if [ $PWX_TEMP_DISABLE -eq 1 ]; then
                status="LogDown</br>TempDisabled"
                loggerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">$status</td>"
                export subjectERPIssue="{ERP Mon Temp Disabled}"
            elif [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                status="LogDown</br>ERP Activity"
                loggerResult="<td style=\"font-size:0.60em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                export subERPMaintenance="{ERP Activity}"
            else
                status="LogDown"
                loggerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$pwxDownColor\">$status</td>"
            fi   
        fi
        ##################################################
        # If Listener is running
        ##################################################

        if [[ $listener_status -gt 0 ]]; then
            if [ $PWX_TEMP_DISABLE -eq 1 ]; then
                status="ListRunning</br>TempDisabled"
                listenerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">$status</td>"
                export subjectERPIssue="{ERP Mon Temp Disabled}"
            elif [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                status="ListRunning</br>ERP Activity"
                listenerResult="<td style=\"font-size:0.60em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                export subERPMaintenance="{ERP Activity}"
            else
                status="Live"
                listenerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$allGoodPwxColor\">$status</td>"
            fi 
        # If Listener is not running
        else
            subListenerDown="**{Listener Down}**"
            if [ $PWX_TEMP_DISABLE -eq 1 ]; then
                status="ListDown</br>TempDisabled"
                listenerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$erpIssueColor\">$status</td>"
                export subjectERPIssue="{ERP Mon Temp Disabled}"
            elif [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                status="ListDown</br>ERP Activity"
                listenerResult="<td style=\"font-size:0.60em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                export subERPMaintenance="{ERP Activity}"
            else
                status="ListDown"
                listenerResult="<td style=\"font-size:0.60em;\" bgcolor=\"$pwxDownColor\">$status</td>"
            fi   
        fi
        echo -e "$(timestamp):\tLogger Count: $logger_status"
        echo -e "$(timestamp):\tListener Count: $listener_status"
        
        result=`echo "${instanceResult}${dbResult}${serverResult}${loggerResult}${listenerResult}"`
        echo -e "$(timestamp):\tHTML Result: $result"
        printstar
        echo $result > $instanceDir/result

    done <  $CDC_PWX_CONFIG_FILE_NON_PROD 
}

get_max_count_of_three_regions_to_set_table_size() {
    na=$1
    emea=$2
    aspac=$3

    if [[ $na -ge $emea ]] && [[ $na -ge $aspac ]]; then
        export greatest=$na
    elif [[ $emea -ge $na ]] && [[ $emea -ge $na ]]; then
        export greatest=$emea
    else
        export greatest=$aspac
    fi

    # export $greatest
    printstar
    echo -e "$(timestamp):\tTable Count Initialized to: $greatest"
    printstar
}

write_data_to_html_file() {
    
    tableCount=$1
    
    cat $ALERT_TEMPLATE_PWX_REPORT_NON_PROD_HEADER_01 > $ALERT_EMAIL_FILE
    echo $(timestamp) >> $ALERT_EMAIL_FILE
    cat $ALERT_TEMPLATE_PWX_REPORT_NON_PROD_HEADER_02 >> $ALERT_EMAIL_FILE
    finalResult=""
    
    for i in $(seq 1 $tableCount); do
        if ls ${NA_NON_PROD}/${i}.* 1> /dev/null 2>&1; then
            na_temp_result=$(< ${NA_NON_PROD}/${i}.*/result)
        else
            na_temp_result="<td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td>"
        fi
        if ls ${EMEA_NON_PROD}/${i}.* 1> /dev/null 2>&1; then
            emea_temp_result=$(< ${EMEA_NON_PROD}/${i}.*/result)
        else
            emea_temp_result="<td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td>"
        fi
        if ls ${ASPAC_NON_PROD}/${i}.* 1> /dev/null 2>&1; then
            aspac_temp_result=$(< ${ASPAC_NON_PROD}/${i}.*/result)
        else
            aspac_temp_result="<td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td><td style=\"font-size:0.60em;\"></td>"
        fi

        finalResult="<tr>${na_temp_result}${emea_temp_result}${aspac_temp_result}</tr>"
        echo $finalResult >> $ALERT_EMAIL_FILE
    done

    cat $ALERT_TEMPLATE_PWX_REPORT_NON_PROD_FOOTER_01 >> $ALERT_EMAIL_FILE
    echo $(timestamp) >> $ALERT_EMAIL_FILE
    cat $ALERT_TEMPLATE_PWX_REPORT_NON_PROD_FOOTER_02 >> $ALERT_EMAIL_FILE
}

SEND_EMAIL_TO_TEAM() {
    echo
    printstar
    echo -e "$(timestamp):\tSending Email to Team..!"

    if [[ ! -z "$subjectERPUnavailable" ]] || [[ ! -z "$subjectERPIssue" ]] || [[ ! -z "$subjectLoggerDown" ]] || [[ ! -z "$subListenerDown" ]] || [[ ! -z "$subERPMaintenance" ]]; then
        subject="{PowerExchange Report}{NON_PROD}${subjectERPUnavailable}${subjectERPIssue}${subjectLoggerDown}${subERPMaintenance}${subListenerDown} - Please Check @$(timestamp)"
    else
        subject="{PowerExchange Report}{NON_PROD} - Success - @$(timestamp)"
    fi

    echo -e "$(timestamp):\tSubject: $subject"
    echo -e "$(timestamp):\tHTML File: $ALERT_EMAIL_FILE"
    echo -e "$(timestamp):\tTo:$CDC_PWX_HOME_NON_PROD_REPORT_TO_LIST"
    echo -e "$(timestamp):\tCC:$CDC_PWX_HOME_NON_PROD_REPORT_CC_LIST"
    echo -e "$(timestamp):\tSending Email...!"

    (
        echo "To: $CDC_PWX_HOME_NON_PROD_REPORT_TO_LIST"
        echo "Cc: $CDC_PWX_HOME_NON_PROD_REPORT_CC_LIST"
        echo "Subject: $subject"
        echo "Content-Type: text/html"
        echo
        cat ${ALERT_EMAIL_FILE}
    ) | /usr/sbin/sendmail -t

    echo -e "$(timestamp):\tEmail Sent...!"
    printstar
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


#####################################################
# Safe Cleanup                                      #
#####################################################


ON_EXIT_SAFE_CLEANUP() {
    echo
    printstar
    echo -e "$(timestamp):\tPerforming Safe Cleanup..!"
    echo -e "$(timestamp):\tPerforming cleanup of temp dir: $tempDir"
    rm -rf $tempDir
    echo -e "$(timestamp):\tSafe Cleanup is completed..!"
    echo -e "$(timestamp):\tScript has completed successfully"
    printstar
    echo
}


main "$@"
