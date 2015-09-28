#!/bin/sh

PROP_FILE=/solution/$CONFIG/data/configuration.properties

ps_host=`/opt/util/parser.sh PS_HOST $PROP_FILE`
ps_user=`/opt/util/parser.sh PS_USERNAME $PROP_FILE`
ps_password=`/opt/util/parser.sh PS_PASSWORD $PROP_FILE`

ps_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $ps_password`

adminui_registration() {
	echo "Running admin ui registration command"

	TIME_OUT=1000
	i=0
	echo  "Logging in to WAMUI"
	TYPE="Content-Type: application/x-www-form-urlencoded"
	ACCEPT="Accept: text/html"
	
	while [ "$i" -le "$TIME_OUT" ]; do
		/usr/bin/curl -H "Host: admin-ui" -H "$ACCEPT" -H "$TYPE" -X POST "admin-ui/iam/siteminder/adminui" -d "username=$ps_user&password=$ps_password&address=$ps_host" | grep -q "Error"
		if [ $? -eq 0 ]; then
		  echo "unable to register adminui...."
			i=`expr $i + 10`
			echo "Sleeping for 10 secs and re trying.........."
			echo $i
			sleep 10
		else
			echo "adminui registration successful"
			echo $i
			retval=0
			break
		fi
	done

	echo "Finished running admin ui registration command.."
}

 TIME_OUT=500
 j=0
 LOGFILE=${JBOSS_HOME}/bin/nohup.out

	while [ -f "$LOGFILE" ] && [ "$j" -le "$TIME_OUT" ]; do
		/bin/grep "CA IAM FW Startup Sequence Complete" "$LOGFILE"
		if [ $? -eq 0 ]; then
			 echo "jboss started successfully"
			 retval=0
			 break
		else
			echo "Jboss haven't started yet"
			 j=`expr $j + 10`
			 echo "Sleeping for 10 secs and checking for jboss.........."
			 sleep 10 
		fi
	done

adminui_registration 


tail -f /dev/null



