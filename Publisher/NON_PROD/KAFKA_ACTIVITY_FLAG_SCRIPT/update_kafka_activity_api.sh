#!/bin/bash
###########################################################################################
# Author: Prashanth Pradeep
# Created on: Sun Dec 13 10:16:58 EST 2020
# Purpose: This Script will update the kafka activity flag in  Publisher NON_PROD Config
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

export region=$1
export updateFlag=$2
export updated_by=$3
export change=$4
export comments=$5
export changeStartTime=$6
export changeEndTime=$7

main() {
    KAFKA_FLAG_UPDATE $region $updateFlag $updated_by $change $comments
}

KAFKA_FLAG_UPDATE(){
    export region=$1
    export updateFlag=$2
    MODULE_HEADER
    echo -e "$(timestamp): Performing Operation: Kafka Flag - $updateFlag in $region"
    echo

    fileCount=`cat $CDC_PUB_CONFIG_FILE_NON_PROD | grep -i $region | grep -i $updateFlag | grep -v grep | wc -l`

    if [ $fileCount -gt 0 ]; then
        echo -e "$(timestamp): Kafka Flag - $updateFlag is already updated in $region"
        echo -e "$(timestamp): **Exiting..!"
        echo
        exit 0
    fi
    echo -e "Taking Backup of the Config File.."
    bkp_date=$(date +"%d%b%Y_%H%M%S")
    backupFileName=$(echo "$NON_PROD_PUB_CONFIG_FILE""_bkp_""$bkp_date")
    export backup_file=$CDC_PUB_CONFIG_BACKUP_HOME_NON_PROD/$backupFileName
    cp $CDC_PUB_CONFIG_HOME_NON_PROD/$NON_PROD_PUB_CONFIG_FILE $backup_file
    sleep 2
    MODULE_HEADER
    echo -e "$(timestamp): Backup has been completed.."
    echo
    echo -e "$(timestamp): Backup File Name: $backup_file"
    echo
    echo -e "$(timestamp): Updating the Kafka Flag $updateFlag in $region"
    echo
    sed -i "/$region/Is/KAFKA_ACTIVITY=./$updateFlag/g" $CDC_PUB_CONFIG_FILE_NON_PROD 
    echo
    echo -e "$(timestamp): The Kafka Flag $updateFlag in $region - Publisher  NON_PROD"
    echo

    # Send Email to Team
    alertFileName=`echo "KAFKA_UPDATE_ALERT_EMAIL_"$(date +"%d%b%Y_%H%M%S")".html"`
    export ALERT_FILE_NAME=$ALERT_EMAILS_KAFKA_ACTIVITY/$alertFileName
    echo "$(timestamp): Sending Email to team..."
    PREPARE_EMAIL_FOR_TEAM
    SEND_EMAIL_TO_TEAM
    echo
    echo "$(timestamp): Email Successfully sent to team..!"
    echo "$(timestamp): Email File: $ALERT_FILE_NAME"
    echo
    
}

PREPARE_EMAIL_FOR_TEAM() {    

    backup_file_sed=`echo $backup_file | sed 's/.\{40\}/&<\/br>/g'`
    comments_sed=`echo $comments | sed 's/.\{40\}/&<\/br>/g'`
    
    cat $ALERT_EMAILS_KAFKA_ACTIVITY_TEMPLATE_HEADER > $ALERT_FILE_NAME

    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""40%"">Kafka Activity Flag:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$updateFlag</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Publisher  NON_PROD Region:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$region</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Updated By:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$updated_by</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Updated at:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$(timestamp)</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    # if [[ ! -z "$change" ]]; then
        echo -e "<tr> " >> $ALERT_FILE_NAME
        echo -e "<th width=""40%"">Change/SR/INC Details:</th>  " >> $ALERT_FILE_NAME
        echo -e "<td width=""60%"">$change</td>" >> $ALERT_FILE_NAME
        echo -e "</tr> " >> $ALERT_FILE_NAME
    # fi
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Comments:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$comments_sed</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    if [[ ! -z "$changeStartTime" ]]; then 
        echo -e "<tr> " >> $ALERT_FILE_NAME
        echo -e "<th width=""40%"">Activity Start Time:</th>  " >> $ALERT_FILE_NAME
        echo -e "<td width=""60%"">$changeStartTime</td>" >> $ALERT_FILE_NAME
        echo -e "</tr> " >> $ALERT_FILE_NAME
    fi
    if [[ ! -z "$changeEndTime" ]]; then 
        echo -e "<tr> " >> $ALERT_FILE_NAME
        echo -e "<th width=""40%"">Activity End Time:</th>  " >> $ALERT_FILE_NAME
        echo -e "<td width=""60%"">$changeEndTime</td>" >> $ALERT_FILE_NAME
        echo -e "</tr> " >> $ALERT_FILE_NAME
    fi
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Config File Backup:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$backup_file_sed</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME

    cat $ALERT_EMAILS_KAFKA_ACTIVITY_TEMPLATE_FOOTER_01 >> $ALERT_FILE_NAME
    echo $(timestamp) >> $ALERT_FILE_NAME
    cat $ALERT_EMAILS_KAFKA_ACTIVITY_TEMPLATE_FOOTER_02 >> $ALERT_FILE_NAME

}

SEND_EMAIL_TO_TEAM() {
    (
        echo "To: $CDC_PUB_HOME_NON_PROD_KAFKA_ACTIVITY_FLAG_SCRIPT_TO_LIST"
        echo "Cc: $CDC_PUB_HOME_NON_PROD_KAFKA_ACTIVITY_FLAG_SCRIPT_CC_LIST"
        echo "Subject: Informatica CDC Automations - KAFKA FLAG Update PUB  NON_PROD - $region - $updateFlag @ $(timestamp)"
        echo "Content-Type: text/html"
        echo
        cat ${ALERT_FILE_NAME}
    ) | /usr/sbin/sendmail -t
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


