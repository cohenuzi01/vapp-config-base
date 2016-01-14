#!/bin/bash

# 03_ps_register - This script registers the Admin UI against the Policy Server. 

##### Constants
PROP_FILE=/solution/$CONFIG/data/configuration.properties
JBOSS_AVAILABILITY_TIME_OUT=500
POLICYSERVER_AVAILABILITY_TIME_OUT=1000
ADMINUI_RESIGTRATION_TIME_OUT=1000
LOGFILE=${JBOSS_HOME}/bin/nohup.out
JBOSS_STARTED_STRING="CA IAM FW Startup Sequence Complete"

ps_host=`/opt/util/parser.sh PS_HOST $PROP_FILE`
ps_user=`/opt/util/parser.sh PS_USERNAME $PROP_FILE`
ps_password=`/opt/util/parser.sh PS_PASSWORD $PROP_FILE`

ps_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $ps_password`


##### Functions
waiting_for_policyserver() {

    echo "[*][$(date +"%T")] - Checking if the policy server is up and running..."
    STARTTIME=$(date +%s)
    # Waiting for the Policy Server service to be ready
    while true; do
        if [ "$(($CURRTIME - $STARTTIME))" -gt "$POLICYSERVER_AVAILABILITY_TIME_OUT" ]; then
            echo "[*][$(date +"%T")] - A timeout was reached ($POLICYSERVER_AVAILABILITY_TIME_OUT seconds) while waiting for the policy server to be available."
            exit 1
        fi

        cat < /dev/tcp/policy-server-master/44443| grep -q "Connection timed out" #If not available will timeout with: bash: connect: Connection timed out.  "curl http://policy-server-master:44443" can also be used.
                
        if [ $? -ne 0 ]; then
            echo "[*][$(date +"%T")] - Policy server is up and running."
            sleep 2 #let's wait a little bit longer, just in case.
            retval=0
            break
        else
            echo "[*][$(date +"%T")] - Unable to connect to the policy server. Waiting for the policy-server to be available ($(($CURRTIME - $STARTTIME))).........."
            sleep 10
            CURRTIME=$(date +%s)            
        fi
    done
}

adminui_registration() {
    echo "[*][$(date +"%T")] - Running Admin UI registration command"

    STARTTIME=$(date +%s)
    TYPE="Content-Type: application/x-www-form-urlencoded"
    ACCEPT="Accept: text/html"
    
    while true; do
        if [ "$(($CURRTIME - $STARTTIME))" -gt "$ADMINUI_RESIGTRATION_TIME_OUT" ]; then
            echo "[*][$(date +"%T")] - A timeout was reached ($ADMINUI_RESIGTRATION_TIME_OUT seconds) while attempting to register Admin UI."
            exit 1
        fi
        
        /usr/bin/curl -s -H "Host: admin-ui" -H "$ACCEPT" -H "$TYPE" -X POST "admin-ui/iam/siteminder/adminui" -d "username=$ps_user&password=$ps_password&address=$ps_host" | grep -q "Error"
        if [ $? -eq 0 ]; then
            echo "[*][$(date +"%T")] - Unable to register Admin UI. Will try again in 10 seconds(($(($CURRTIME - $STARTTIME)))).........."
            sleep 10
            CURRTIME=$(date +%s)            
        else
            echo "[*][$(date +"%T")] - AdminUI registration completed successfully."
            retval=0
            break
        fi
    done

}

waiting_for_jboss()
{
    j=0
    while [ -f "$LOGFILE" ]; do
        if [ "$j" -gt "$JBOSS_AVAILABILITY_TIME_OUT" ]; then
            echo "[*][$(date +"%T")] - A timeout was reached ($POLICYSERVER_AVAILABILITY_TIME_OUT seconds) while waiting for the JBoss to start."
            exit 1
        fi
        /bin/grep "$JBOSS_STARTED_STRING" "$LOGFILE"
        if [ $? -eq 0 ]; then
             echo "[*][$(date +"%T")] - JBoss started successfully."
             retval=0
             break
        else
            echo "[*][$(date +"%T")] - JBoss did not start yet. Waiting for JBoss to start ($j).........."
             j=`expr $j + 10`
             sleep 10
        fi
    done
}

##### Main
waiting_for_jboss

waiting_for_policyserver

adminui_registration

tail -f /dev/null
