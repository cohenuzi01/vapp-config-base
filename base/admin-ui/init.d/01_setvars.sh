#!/bin/sh

echo "[*] starting extraction and copy of files"

echo "[*] JBOSS_HOME=${JBOSS_HOME}"

cp /tmp/caderby-service.xml ${JBOSS_HOME}/server/default/deploy/
cp /tmp/iam_siteminder_imarchivedb-ds.xml ${JBOSS_HOME}/server/default/deploy/
cp /tmp/iam_siteminder_imtaskpersistencedb-ds.xml ${JBOSS_HOME}/server/default/deploy
cp /tmp/iam_siteminder_objectstore-ds.xml ${JBOSS_HOME}/server/default/deploy/



tar zxf /tmp/wamui-files.tar.gz -C /tmp/
ant -buildfile /tmp/wamui-files/build.xml install -Ddirectory=${JBOSS_HOME} -Dhost=admin-ui.ca.com -Dport=8080
tar zxf /tmp/lib.tar.gz -C /tmp/
cp -r /tmp/lib/* ${JBOSS_HOME}/server/default/lib
rm -rf /tmp/lib/
rm -rf /tmp/lib.tar.gz
tar zxf /tmp/iam_siteminder.ear.tar.gz -C /tmp/
cp -r /tmp/iam_siteminder.ear ${JBOSS_HOME}/server/default/deploy/
tar zxf /tmp/castylesr5.1.1.ear.tar.gz -C /tmp/
cp -r /tmp/castylesr5.1.1.ear ${JBOSS_HOME}/server/default/deploy/
cp -rf /tmp/login-config.xml ${JBOSS_HOME}/server/default/conf/

echo "[*] finished extraction and copy of files"

echo "[*] Set configuration variables: starting"



sed -i "s|{JBOSS_HOME}|${JBOSS_HOME}|g" ${JBOSS_HOME}/server/default/deploy/iam_siteminder_imarchivedb-ds.xml
sed -i "s|{JBOSS_HOME}|${JBOSS_HOME}|g" ${JBOSS_HOME}/server/default/deploy/iam_siteminder_imtaskpersistencedb-ds.xml
sed -i "s|{JBOSS_HOME}|${JBOSS_HOME}|g" ${JBOSS_HOME}/server/default/deploy/iam_siteminder_objectstore-ds.xml

echo "[*] Set configuration variables: complete"

#Temporary fix for entropy issue. Will be removed/modified once alternative approach is confirmed.
mv /dev/random /dev/origrandom
ln -s /dev/urandom /dev/random
