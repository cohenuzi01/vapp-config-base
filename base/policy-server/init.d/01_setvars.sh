#!/bin/sh

echo "[*] Set configuration variables: starting"

ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties

ps_home=`/opt/util/parser.sh nete_ps_root $ENV_PROP_FILE`
java_root=`/opt/util/parser.sh nete_java_root $ENV_PROP_FILE`
fips_mode=`/opt/util/parser.sh nete_fips_mode $ENV_PROP_FILE`

sed -i "s|ps-loc|$ps_home|g" /opt/CA/siteminder/ca_ps_env.ksh
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/ca_ps_env.ksh
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/bin/smconsole
sed -i "s|nete_jre_root|$java_root/jre|g" /opt/CA/siteminder/ca_ps_env.ksh
sed -i "s|fips_value|$fips_mode|g" /opt/CA/siteminder/ca_ps_env.ksh
sed -i "s|nete_doc_root|$ps_home/ca_documents|g" /opt/CA/siteminder/ca_ps_env.ksh
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/S98sm
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/ca-snmp-config.sh
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/smprofile.ksh
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/start-all
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/start-ps
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/stop-all
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/stop-ps
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/smstop
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/smpolsrv
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/smmon
sed -i "s|sm_home|$ps_home|g" /opt/CA/siteminder/config/JVMOptions.txt
sed -i "s|nete_ps_root|$ps_home|g" /opt/CA/siteminder/db/*.ini
sed -i "s|sm_home|$ps_home|g" /opt/CA/siteminder/config/properties/smkeydatabase.properties
sed -i "s|<ARCOT_HOME>|/opt/CA/aas|g" /opt/CA/aas/sbin/arrfenv

ln -s $JAVA_HOME/lib/i386/server/libjvm.so /usr/lib/libjvm.so

source /opt/CA/siteminder/ca_ps_env.ksh

echo "[*] Set configuration variables: complete"

#Temporary fix for entropy issue. Will be removed/modified once alternative approach is confirmed.
mv /dev/random /dev/origrandom
ln -s /dev/urandom /dev/random