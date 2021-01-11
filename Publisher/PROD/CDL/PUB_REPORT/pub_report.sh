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
export tempDir=$(mktemp -d $CDC_PUB_HOME_PROD_CDL_TEMPDIR/temp.XXXXXXXXXX)
export NA_PROD=$(mktemp -d $tempDir/NA_PROD.XXXXXXXXXX)
export EMEA_PROD=$(mktemp -d $tempDir/EMEA_PROD.XXXXXXXXXX)
export ASPAC_PROD=$(mktemp -d $tempDir/ASPAC_PROD.XXXXXXXXXX)
export NA_COUNT=0
export EMEA_COUNT=0
export ASPAC_COUNT=0
export ALERT_EMAIL_FILE=${ALERT_EMAILS_PUB_REPORT_CDL_PROD}/ALERT_EMAIL_FILE_$(date +"%d%b%Y_%H%M%S").html
export subjectLag=""
export subjectPubDown=""
export subIssue=""

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

        if [[ ${RECLINE} != *"LIVE=1"* ]];then
             continue
        fi
        pub_fail_flag="false"
        pub_checkpoint_lag_flag="false"

        export instance=`echo $RECLINE | cut -d":" -f1 | cut -d"=" -f2`
        export PWX_ERP_NAME=`echo $RECLINE | cut -d":" -f2 | cut -d"=" -f2`
        export ENV=`echo $RECLINE | cut -d":" -f3 | cut -d"=" -f2`
        export LIVE=`echo $RECLINE | cut -d":" -f4 | cut -d"=" -f2`
        export KAFKA_ACTIVITY=`echo $RECLINE | cut -d":" -f5 | cut -d"=" -f2`
        export PUB_UID=`echo $RECLINE | cut -d":" -f7 | cut -d"=" -f2`
        export SERVER=`echo $RECLINE | cut -d":" -f8 | cut -d"=" -f2`
        export PWX_ERP_ACTIVITY=`cat $CDC_PWX_CONFIG_FILE_PROD | grep -i $PWX_ERP_NAME | cut -d":" -f8 |  cut -d "=" -f2`
        export PWX_TEMP_DISABLE=`cat $CDC_PWX_CONFIG_FILE_PROD | grep -i $PWX_ERP_NAME | cut -d":" -f9 | cut -d "=" -f2`
        export PWX_SERVER_TIMEZONE=`cat $CDC_PWX_CONFIG_FILE_PROD | grep -i $PWX_ERP_NAME | cut -d":" -f11 | cut -d "=" -f2`

        printstar
        echo -e "$(timestamp):\tProcessing $instance"
        echo -e "$(timestamp):\tENV: $ENV"
        echo -e "$(timestamp):\tLIVE: $LIVE"
        echo -e "$(timestamp):\tPWX_ERP_NAME: $PWX_ERP_NAME"
        echo -e "$(timestamp):\tKAFKA_ACTIVITY: $KAFKA_ACTIVITY"
        echo -e "$(timestamp):\tPWX_TEMP_DISABLE: $PWX_TEMP_DISABLE"
        echo -e "$(timestamp):\tPWX_ERP_ACTIVITY: $PWX_ERP_ACTIVITY"
        echo -e "$(timestamp):\tPWX_SERVER_TIMEZONE: $PWX_SERVER_TIMEZONE"
        echo -e "$(timestamp):\tPUB_UID: $PUB_UID"
        echo -e "$(timestamp):\tSERVER: $SERVER"

    
        if [ "$ENV" == "NA_PROD" ]; then
            ZONE="EST"
            TZ_FLAG="EST"
            export NA_COUNT=$((NA_COUNT+1))
            export instanceDir=$(mktemp -d ${NA_PROD}/${NA_COUNT}.XXXXXXXXXX)       
        elif [ "$ENV" == "EMEA_PROD" ]; then
            ZONE="CET"
            TZ_FLAG="CET"
            export EMEA_COUNT=$((EMEA_COUNT+1))
            export instanceDir=$(mktemp -d ${EMEA_PROD}/${EMEA_COUNT}.XXXXXXXXXX)
        elif [ "$ENV" == "ASPAC_PROD" ]; then
            ZONE="Singapore"
            TZ_FLAG="SGT"
            export ASPAC_COUNT=$((ASPAC_COUNT+1))
            export instanceDir=$(mktemp -d ${ASPAC_PROD}/${ASPAC_COUNT}.XXXXXXXXXX)
        fi


        export CHECKPOINT=/apps/Informatica/PWX_CDC_Publisher/${instance}/checkpoint/checkpoint
        export SSH_SCRIPT="DEC_CHECKPOINT=\$(echo \"ibase=16;obase=A;\$(cat ${CHECKPOINT} | cut -d\",\" -f9 | cut -d\"#\" -f1)\" | bc 2> /dev/null);DEC_DATE=\$(echo \${DEC_CHECKPOINT} | awk '{print substr(\$0,3,2)\"/\"substr(\$0,5,2)\"/\"substr(\$0,1,2)\" \"substr(\$0,7,2)\":\"substr(\$0,9,2)}' 2> /dev/null);CHECKPOINT_DATE=\$(date -d\"\$DEC_DATE\" +\"%d-%b-%Y %H:%M \" 2> /dev/null);CHECKPOINT_EPOCH=\$(date -d\"\$CHECKPOINT_DATE\" +\"%s\" 2> /dev/null);EPOCH_TIME=\$(date +\"%s\");PUB_STATUS=\$(ps -eaf | grep PwxCDCPublisher.sh | grep -v grep | grep $instance | wc -l);echo \"\$CHECKPOINT_DATE|\$PUB_STATUS\";"

        export SSH_RESULT=`ssh -q -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=600 -n $PUB_UID@$SERVER $SSH_SCRIPT`

        if [ -z "$SSH_RESULT" ]; then
            result="<td style=\"font-size:0.65em;\">$instance</td><td style=\"font-size:0.65em;\">Not Available</td><td style=\"font-size:0.65em;\" bgcolor=\"$pubDownColor\">Not Available</td>"
            echo $result > $instanceDir/result
            echo $result
            subjectPubDown="**{Pub Down}**"
            continue
        fi
    
        instanceResult="<td style=\"font-size:0.65em;\">$instance</td>"
        checkpoint_date=`echo $SSH_RESULT | cut -d"|" -f1`
        pub_status=`echo $SSH_RESULT | cut -d"|" -f2`
        PUBLISHER_PROD_EPOCH=$(TZ=${ZONE} date +"%s")
        lag="false"
        
        if [ -z "$checkpoint_date" ]; then
            instance_checkpoint_date_standardised_timezone="No Checkpoint"
            lag="No Check"
            export subIssue="{Issue}"
            
        else 
            instance_epoch=$(date --date="TZ=\"$PWX_SERVER_TIMEZONE\" $checkpoint_date" +"%s" )
            # First convert the checkpoint time to EST -- Sandbox Local Time
            instance_checkpoint_date_standardised_timezone=$(date --date="TZ=\"$PWX_SERVER_TIMEZONE\" 
            $checkpoint_date" +"%d-%b-%Y %H:%M:%S" )
            # Then Convert the time to publisher server local time
            instance_checkpoint_date_standardised_timezone=`TZ="$ZONE" date -d "$instance_checkpoint_date_standardised_timezone EST" +"%d-%b-%Y %H:%M:%S $TZ_FLAG"`
            
            timeDiff=$(($PUBLISHER_PROD_EPOCH - $instance_epoch))
            timeDay=$(($timeDiff / 86400))
            timeDiff=$(($timeDiff % 86400))
            timeHours=$(($timeDiff / 3600 ))
            timeDiff=$(($timeDiff % 3600 ))
            timeMinutes=$(($timeDiff / 60))

            if [ $timeHours -ge 2 ] || [ $timeDay -ge 1 ]; then
                export subjectLag="{Pub Lag}"
                lag="Lag By: $timeDay Days, $timeHours hours"
            fi
        fi

        # If Publisher is running
        if [[ $pub_status -gt 0 ]]; then
            # Pub is running and there is no lag
            if [ "$lag" == "false" ]; then
               if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>ERP Activity"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>KAFKA Activity"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>"
                    export subIssue="{Kafka Activity}"  
                else
                    status="Current"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$allGoodPubColor\">$status</td>"
                fi
            # Pub Running but there is no checkpoint
            elif [ "$lag" == "No Check" ]; then
                if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>ERP Activity</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>KAFKA Activity</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>" 
                    export subIssue="{Kafka Activity}" 
                else
                    status="Current</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$allGoodPubColor\">$status</td>"
                fi 
            # Pub Running but there is lag
            else
                if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>$lag</br>ERP Activity"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubRunning</br>$lag</br>KAFKA Activity"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>"
                    export subIssue="{Kafka Activity}"  
                else
                    status="$lag"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$pubCDCDataLagColor\">$status</td>"
                fi 
            fi
        # If Publisher not running
        else
        subjectPubDown="**{Pub Down}**"
        if [ "$lag" == "false" ]; then
               if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>ERP Activity"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"  
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>KAFKA Activity"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>"  
                    export subIssue="{Kafka Activity}"  
                else
                    status="PubDown"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$pubDownColor\">$status</td>"
                fi
                
            elif [ "$lag" == "No Check" ]; then
                if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>ERP Activity</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"  
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>KAFKA Activity</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>" 
                    export subIssue="{Kafka Activity}"   
                else
                    status="PubDown</br>No Checkpoint"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$pubDownColor\">$status</td>"
                fi 
            else
                if [ $PWX_TEMP_DISABLE -eq 1 ] || [ $PWX_ERP_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>$lag</br>ERP Activity"
                    statusResult="<td style=\"font-size:0.65em;color: white;\" bgcolor=\"$erpMaintenanceColor\">$status</td>"
                    export subIssue="{ERP Activity}"  
                    
                elif [ $KAFKA_ACTIVITY -eq 1 ]; then
                    status="PubDown</br>$lag</br>KAFKA Activity"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$kafkaActivityColor\">$status</td>"
                    export subIssue="{Kafka Activity}"    
                else
                    status="PubDown</br>$lag"
                    statusResult="<td style=\"font-size:0.65em;\" bgcolor=\"$pubDownColor\">$status</td>"
                fi 
            fi
        fi
        checkpointResult="<td style=\"font-size:0.65em;\">$instance_checkpoint_date_standardised_timezone</td>"
        result=`echo "${instanceResult}${checkpointResult}${statusResult}"`
        echo -e "$(timestamp):\tlag: $lag"
        echo -e "$(timestamp):\tcheckpoint_date: $instance_checkpoint_date_standardised_timezone"
        echo -e "$(timestamp):\tHTML Result: $result"
        printstar
        echo $result > $instanceDir/result

    done <  $CDC_PUB_CONFIG_FILE_CDL_PROD 
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
    
    cat $ALERT_TEMPLATE_PUB_REPORT_CDL_PROD_HEADER_01 > $ALERT_EMAIL_FILE
    echo $(timestamp) >> $ALERT_EMAIL_FILE
    cat $ALERT_TEMPLATE_PUB_REPORT_CDL_PROD_HEADER_02 >> $ALERT_EMAIL_FILE
    finalResult=""
    
    for i in $(seq 1 $tableCount); do
        if ls ${NA_PROD}/${i}.* 1> /dev/null 2>&1; then
            na_temp_result=$(< ${NA_PROD}/${i}.*/result)
        else
            na_temp_result="<td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td>"
        fi
        if ls ${EMEA_PROD}/${i}.* 1> /dev/null 2>&1; then
            emea_temp_result=$(< ${EMEA_PROD}/${i}.*/result)
        else
            emea_temp_result="<td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td>"
        fi
        if ls ${ASPAC_PROD}/${i}.* 1> /dev/null 2>&1; then
            aspac_temp_result=$(< ${ASPAC_PROD}/${i}.*/result)
        else
            aspac_temp_result="<td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td><td style=\"font-size:0.65em;\"></td>"
        fi

        finalResult="<tr>${na_temp_result}${emea_temp_result}${aspac_temp_result}</tr>"
        echo $finalResult >> $ALERT_EMAIL_FILE
    done

    cat $ALERT_TEMPLATE_PUB_REPORT_CDL_PROD_FOOTER_01 >> $ALERT_EMAIL_FILE
    echo $(timestamp) >> $ALERT_EMAIL_FILE
    cat $ALERT_TEMPLATE_PUB_REPORT_CDL_PROD_FOOTER_02 >> $ALERT_EMAIL_FILE
}

SEND_EMAIL_TO_TEAM() {
    echo
    printstar
    echo -e "$(timestamp):\tSending Email to Team..!"

    if [[ ! -z "$subjectLag" ]] || [[ ! -z "$subjectPubDown" ]] || [[ ! -z "$subIssue" ]]; then
        subject="{Publisher Report}{CDL}${subjectLag}${subjectPubDown}${subIssue} - Please Check @$(timestamp)"
    else
        subject="{Publisher Report}{CDL} - Success - @$(timestamp)"
    fi

    echo -e "$(timestamp):\tSubject: $subject"
    echo -e "$(timestamp):\tHTML File: $ALERT_EMAIL_FILE"
    echo -e "$(timestamp):\tTo:$CDC_PUB_HOME_PROD_CDL_PUB_REPORT_TO_LIST"
    echo -e "$(timestamp):\tCC:$CDC_PUB_HOME_PROD_CDL_PUB_REPORT_CC_LIST"
    echo -e "$(timestamp):\tSending Email...!"

    (
        echo "To: $CDC_PUB_HOME_PROD_CDL_PUB_REPORT_TO_LIST"
        echo "Cc: $CDC_PUB_HOME_PROD_CDL_PUB_REPORT_CC_LIST"
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
