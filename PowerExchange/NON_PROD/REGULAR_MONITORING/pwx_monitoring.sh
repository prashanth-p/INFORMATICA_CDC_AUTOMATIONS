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


main() {
    check_status_and_send_alert_email
}

check_status_and_send_alert_email() {
    while IFS= read -r RECLINE
    do
        
        if [[ ${RECLINE} != *"MONITORING_ENABLED=1"* ]];then
             continue
        fi

        export PWX_ERP_NAME=`echo $RECLINE | cut -d":" -f1 | cut -d"=" -f2`
        export PWX_DB_NAME=`echo $RECLINE | cut -d":" -f2 | cut -d"=" -f2`
        
        export PWX_SERVER=`echo $RECLINE | cut -d":" -f5 | cut -d"=" -f2`
        export PWX_USER=`echo $RECLINE | cut -d":" -f4 | cut -d"=" -f2`
        export ENV=`echo $RECLINE | cut -d":" -f10 | cut -d"=" -f2`
        export MONITORING_ENABLED=`echo $RECLINE | cut -d":" -f6 | cut -d"=" -f2`
        export PWX_ERP_ACTIVITY=`echo $RECLINE | cut -d":" -f8 | cut -d"=" -f2`
        export PWX_TEMP_DISABLE=`echo $RECLINE | cut -d":" -f9 | cut -d"=" -f2`


        export PWX_ERP_DL=`echo $RECLINE | cut -d":" -f12 | cut -d"=" -f2`
        export PWX_ERP_ASSIGNMENT_GROUP=`echo $RECLINE | cut -d":" -f13 | cut -d"=" -f2`
        export PWX_ERP_REGION=`echo $RECLINE | cut -d":" -f10 | cut -d"=" -f2`
        
        
        printstar
        echo -e "$(timestamp):\tProcessing $PWX_ERP_NAME"
        echo -e "$(timestamp):\tENV: $ENV"
        echo -e "$(timestamp):\tLIVE STATUS: $MONITORING_ENABLED"
        echo -e "$(timestamp):\tPWX_ERP_NAME: $PWX_ERP_NAME"
        echo -e "$(timestamp):\tPWX_USER: $PWX_USER"
        echo -e "$(timestamp):\tPWX_SERVER: $PWX_SERVER"
        echo -e "$(timestamp):\tPWX_DB_NAME: $PWX_DB_NAME"
        echo -e "$(timestamp):\tPWX_ERP_DL: $PWX_ERP_DL"
        echo -e "$(timestamp):\tPWX_ERP_ASSIGNMENT_GROUP: $PWX_ERP_ASSIGNMENT_GROUP"

        export PWX_ERP_NAME_SPACE=`echo $PWX_ERP_NAME | tr '_' ' '`
        echo -e "$(timestamp):\tPWX_ERP_NAME_SPACE: $PWX_ERP_NAME_SPACE"

        if [[ $PWX_TEMP_DISABLE -eq 1 ]] || [[ $PWX_ERP_ACTIVITY -eq 1 ]]; then
            echo -e "$(timestamp):\tPWX_ERP_ACTIVITY: $PWX_ERP_ACTIVITY"
            echo -e "$(timestamp):\tPWX_TEMP_DISABLE: $PWX_TEMP_DISABLE"

            echo -e "$(timestamp):\tMonitoring for Instance $PWX_ERP_NAME has been Temp disabled..!"
            echo -e "$(timestamp):\tProceeding with next instance..!"
            continue
        fi

        export SSH_SCRIPT="LOGGER_STATUS=\$(ps -ef | grep pwxccl | grep -v grep | wc -l);LISTENER_STATUS=\$(ps -ef | grep dtl | grep -v grep | wc -l);echo \"\$LOGGER_STATUS|\$LISTENER_STATUS\";"

        export SSH_RESULT=`ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=600 -n $PWX_USER@$PWX_SERVER $SSH_SCRIPT`

        if [ -z "$SSH_RESULT" ]; then
            export subject="$PWX_ERP_NAME_SPACE running on server $PWX_SERVER with the component logger and listener is not running: Server Not Reachable: SSH ERROR @ timestamp $(timestamp)"
            export body="$subject </br>- Please Check if there is an activity in ERP </br>- Please Check SSH Connectivity</br>"  
            export logger_status="<td width=\"70%\" bgcolor=\"tomato\">Logger Status Unknown</td>"
            export listener_status="<td width=\"70%\" bgcolor=\"tomato\">Listener Status Unknown</td>"
            
            PREPARE_EMAIL_FOR_TEAM
            printstar
            continue
        fi
        
        logger_count=`echo $SSH_RESULT | cut -d"|" -f1`
        listener_count=`echo $SSH_RESULT | cut -d"|" -f2`
        
        echo -e "$(timestamp):\tLogger Count: $logger_count"
        echo -e "$(timestamp):\tListener Count: $listener_count"
        
        
        
        if [[ $logger_count -eq 0 ]] && [[ $listener_count -eq 0 ]]; then
            export subject="$PWX_ERP_NAME_SPACE running on server $PWX_SERVER with the component logger and listener is not running @ timestamp $(timestamp)"
            export body="$subject"  
            export logger_status="<td width=\"70%\" bgcolor=\"tomato\">Logger Not Running</td>"
            export listener_status="<td width=\"70%\" bgcolor=\"tomato\">Listener Not Running</td>"
            PREPARE_EMAIL_FOR_TEAM
        # If Logger is not running
        elif [[ $logger_count -eq 0 ]]; then
            export subject="$PWX_ERP_NAME_SPACE running on server $PWX_SERVER with the component logger is not running @ timestamp $(timestamp)"
            export body="$subject" 
            export logger_status="<td width=\"70%\" bgcolor=\"tomato\">Logger Not Running</td>"
            export listener_status="<td width=\"70%\" bgcolor=\"$allGoodPwxColor\">Listener Running</td>"
            PREPARE_EMAIL_FOR_TEAM
        elif [[ $listener_count -eq 0 ]]; then
            export subject="$PWX_ERP_NAME_SPACE running on server $PWX_SERVER with the component listener is not running @ timestamp $(timestamp)"
            export body="$subject" 
            export logger_status="<td width=\"70%\" bgcolor=\"$allGoodPwxColor\">Logger Running</td>"
            export listener_status="<td width=\"70%\" bgcolor=\"tomato\">Listener Not Running</td>"
            PREPARE_EMAIL_FOR_TEAM
        else
            echo -e "$(timestamp):\tLogger and Listener is Up and Running Fine..!"
        fi

        printstar

    done <  $CDC_PWX_CONFIG_FILE_NON_PROD 
}

PREPARE_EMAIL_FOR_TEAM() {    
    alertFileName=`echo "REGULAR_MONITORING_ALERT_EMAIL_${PWX_ERP_NAME}_"$(date +"%d%b%Y_%H%M%S")".html"`
    export ALERT_FILE_NAME=$ALERT_EMAILS_REGULAR_MONITORING_PWX_NON_PROD/$alertFileName
    echo -e "$(timestamp):\tLogger Status: $logger_status"
    echo -e "$(timestamp):\tListener Status: $listener_status"
    
    #pwx_erp_dl_sed=`echo $PWX_ERP_DL | sed 's/.\{40\}/&<\/br>/g'`
    
    cat $ALERT_EMAILS_REGULAR_MONITORING_PWX_NON_PROD_TEMPLATE_HEADER_01 > $ALERT_FILE_NAME
    echo "<p>$body</p></br>" >> $ALERT_FILE_NAME
    cat $ALERT_EMAILS_REGULAR_MONITORING_PWX_NON_PROD_TEMPLATE_HEADER_02 >> $ALERT_FILE_NAME

    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""30%"">PowerExchange ERP:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_ERP_NAME_SPACE</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME

    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""30%"">PWX ERP Server:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_SERVER</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME

    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""30%"">PWX ERP DB:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_DB_NAME</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME


    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""30%"">PWX ERP DL:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_ERP_DL</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""30%"">ERP Assignment Group:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_ERP_ASSIGNMENT_GROUP</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""30%"">ERP Region:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""70%"">$PWX_ERP_REGION</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""30%"">Logger Status:</th>  " >> $ALERT_FILE_NAME
    echo -e "$logger_status" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""30%"">Listener Status:</th>  " >> $ALERT_FILE_NAME
    echo -e "$listener_status" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    
    cat $ALERT_EMAILS_REGULAR_MONITORING_PWX_NON_PROD_TEMPLATE_FOOTER_01 >> $ALERT_FILE_NAME
    echo $(timestamp) >> $ALERT_FILE_NAME
    cat $ALERT_EMAILS_REGULAR_MONITORING_PWX_NON_PROD_TEMPLATE_FOOTER_02 >> $ALERT_FILE_NAME

    SEND_EMAIL_TO_TEAM
}

SEND_EMAIL_TO_TEAM() {
    echo -e "$(timestamp):\tSubject: $subject"
    echo -e "$(timestamp):\tBody: $body"
    echo -e "$(timestamp):\tTo: $CDC_PWX_HOME_NON_PROD_REGULAR_MONITORING_FLAG_SCRIPT_TO_LIST"
    echo -e "$(timestamp):\tCC: $CDC_PWX_HOME_NON_PROD_REGULAR_MONITORING_FLAG_SCRIPT_CC_LIST"
    echo -e "$(timestamp):\tAlert_Email: $ALERT_FILE_NAME"
    (
        echo "To: $CDC_PWX_HOME_NON_PROD_REGULAR_MONITORING_FLAG_SCRIPT_TO_LIST"
        echo "Cc: $CDC_PWX_HOME_NON_PROD_REGULAR_MONITORING_FLAG_SCRIPT_CC_LIST"
        echo "Subject: $subject"
        echo "Content-Type: text/html"
        echo
        cat ${ALERT_FILE_NAME}
    ) | /usr/sbin/sendmail -t
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


main "$@"
