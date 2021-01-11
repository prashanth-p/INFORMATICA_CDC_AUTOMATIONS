

PWX_PROD_PATH=/apps/Admin_Scripts/NODE_OUTAGE_LOGGING/xcode/pwx_monitoring/PWX_PROD
PWX_CONFIG_PATH=$PWX_PROD_PATH/Config
CONFIG_FILE=$PWX_CONFIG_PATH/PWX_CONFIG_PROD.cfg


SCRIPT="ps -ef | grep pmon | grep -v grep | cut -d\"_\" -f3"
SCRIPT1="ps -ef | grep pmon | grep -v grep | cut -d\"_\" -f4 | wc -l"

while IFS="" read -r RECLINE
do

        PWX_USER_ID=`echo $RECLINE | cut -d":" -f3 | cut -d"=" -f2`
        PWX_SERVER=`echo $RECLINE | cut -d":" -f4 | cut -d"=" -f2`
                output=`ssh -q -o PasswordAuthentication=no -o ConnectTimeout=600 -n $PWX_USER_ID@$PWX_SERVER $SCRIPT`
#output1=`ssh -q -o PasswordAuthentication=no -o ConnectTimeout=600 -n $PWX_USER_ID@$PWX_SERVER $SCRIPT1`

                echo $output 
                done < $CONFIG_FILE


