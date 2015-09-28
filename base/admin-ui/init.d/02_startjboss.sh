#!/bin/sh

echo "[*] JBoss: starting"

#Run in the foreground so that the container does not exit
nohup ${JBOSS_HOME}/bin/run.sh > $JBOSS_HOME/bin/nohup.out &

echo "[*] JBoss: started command initiated"



