#!/bin/bash
###########################################################################################
# Author: Prashanth Pradeep
# Created on: Sun Dec 13 10:16:58 EST 2020
# Purpose: This Script will update the Monitoring activity flag in NON_CDL Publisher Prod Config
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

export pub_instance=$1
export region=`cat $CDC_PUB_CONFIG_FILE_NON_CDL_PROD | grep -i $pub_instance | cut -d":" -f3 | cut -d"=" -f2`
export updateFlag=$2
export updated_by=$3
export change=$4
export comments=$5
export changeStartTime=$6
export changeEndTime=$7

main() {
    MON_FLAG_UPDATE
}

MON_FLAG_UPDATE(){
   
    MODULE_HEADER
    echo -e "$(timestamp): Performing Operation: Enable/Diable Flag - $pub_instance: $updateFlag in $region"
    echo

    fileCount=`cat $CDC_PUB_CONFIG_FILE_NON_CDL_PROD | grep -i $pub_instance | grep -i $updateFlag | grep -v grep | wc -l`

    if [ $fileCount -gt 0 ]; then
        echo -e "$(timestamp): Monitoring Enable/Disable Flag - $pub_instance: $updateFlag is already updated in $region"
        echo -e "$(timestamp): **Exiting..!"
        echo
        exit 0
    fi
    echo -e "Taking Backup of the Config File.."
    bkp_date=$(date +"%d%b%Y_%H%M%S")
    backupFileName=$(echo "$NON_CDL_CONFIG_FILE""_bkp_""$bkp_date")
    export backup_file=$CDC_PUB_CONFIG_BACKUP_HOME_PROD_NON_CDL/$backupFileName
    cp $CDC_PUB_CONFIG_HOME_PROD_NON_CDL/$NON_CDL_CONFIG_FILE $backup_file
    sleep 2
    MODULE_HEADER
    echo -e "$(timestamp): Backup has been completed.."
    echo
    echo -e "$(timestamp): Backup File Name: $backup_file"
    echo
    echo -e "$(timestamp): Updating the Monitoring Flag: $pub_instance: $updateFlag in $region"
    echo
    sed -i "/$pub_instance/Is/LIVE=./$updateFlag/g" $CDC_PUB_CONFIG_FILE_NON_CDL_PROD 
    echo
    echo -e "$(timestamp): The Monitoring Flag $pub_instance: $updateFlag has been updated in $region - Publisher NON_CDL Prod"
    echo

    # Send Email to Team
    alertFileName=`echo "MONITORING_UPDATE_ALERT_EMAIL_"$(date +"%d%b%Y_%H%M%S")".html"`
    export ALERT_FILE_NAME=$ALERT_EMAILS_MONITORING_ACTIVITY_NON_CDL/$alertFileName
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
    
    cat $ALERT_EMAILS_MONITORING_ACTIVITY_NON_CDL_TEMPLATE_HEADER > $ALERT_FILE_NAME

    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""40%"">Publisher Instance:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$pub_instance</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th  width=""40%"">Monitoring Activity Flag:</th>  " >> $ALERT_FILE_NAME
    echo -e "<td width=""60%"">$updateFlag</td>" >> $ALERT_FILE_NAME
    echo -e "</tr> " >> $ALERT_FILE_NAME
    echo -e "<tr> " >> $ALERT_FILE_NAME
    echo -e "<th width=""40%"">Publisher NON_CDL Prod Region:</th>  " >> $ALERT_FILE_NAME
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

    cat $ALERT_EMAILS_MONITORING_ACTIVITY_NON_CDL_TEMPLATE_FOOTER_01 >> $ALERT_FILE_NAME
    echo $(timestamp) >> $ALERT_FILE_NAME
    cat $ALERT_EMAILS_MONITORING_ACTIVITY_NON_CDL_TEMPLATE_FOOTER_02 >> $ALERT_FILE_NAME

}

SEND_EMAIL_TO_TEAM() {
    (
        echo "To: $CDC_PUB_HOME_PROD_NON_CDL_MONITORING_ACTIVITY_FLAG_SCRIPT_TO_LIST"
        echo "Cc: $CDC_PUB_HOME_PROD_NON_CDL_MONITORING_ACTIVITY_FLAG_SCRIPT_CC_LIST"
        echo "Subject: Informatica CDC Automations - Pub Monitoring Flag Update NON_CDL PROD - $pub_instance - $region - $updateFlag @ $(timestamp)"
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
    echo "Module : update_monitoring_activity.sh"
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
