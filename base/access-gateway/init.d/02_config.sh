#!/bin/bash

# 02_config - This script registers the Admin UI against the Policy Server. 

##### Constants
ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties
POLICYSERVER_AVAILABILITY_TIME_OUT=1000

#NETE_SPS_ROOT is defined at the docker image level (as /opt/CA/secure-proxy)
sps_home=$NETE_SPS_ROOT
WAConf_file="$sps_home/proxy-engine/conf/defaultagent/WebAgent.conf"
sm_host_file="$sps_home/proxy-engine/conf/defaultagent/SmHost.conf"    

ps_host=`/opt/util/parser.sh PS_HOST $ENV_PROP_FILE`
admin_reg_name=`/opt/util/parser.sh ADMIN_REG_NAME $ENV_PROP_FILE`
admin_reg_pswd=`/opt/util/parser.sh ADMIN_REG_PASSWORD $ENV_PROP_FILE`
trusted_host_name=`/opt/util/parser.sh TRUSTED_HOST_NAME $ENV_PROP_FILE`
ps_hco_name=`/opt/util/parser.sh HOST_CONFIG_OBJ $ENV_PROP_FILE`
fips_mode=`/opt/util/parser.sh SPS_FIPS_VALUE $ENV_PROP_FILE`

hostname=`/opt/util/parser.sh VIRTUAL_HOST_NAMES $ENV_PROP_FILE`
aco=`/opt/util/parser.sh AGENT_CONFIG_OBJ $ENV_PROP_FILE`
enable_WA=`/opt/util/parser.sh ENABLE_WEBAGENT $ENV_PROP_FILE`
enable_fed_gateway=`/opt/util/parser.sh ENABLE_FED_GATEWAY $ENV_PROP_FILE`
 
httpd_port=`/opt/util/parser.sh APACHE_HTTP_PORT $ENV_PROP_FILE`
httpd_ssl_port=`/opt/util/parser.sh APACHE_SSL_PORT $ENV_PROP_FILE`
server_admin=`/opt/util/parser.sh APACHE_ADMIN_EMAIL $ENV_PROP_FILE`

tomcat_http_port=`/opt/util/parser.sh TOMCAT_HTTP_PORT $ENV_PROP_FILE`
tomcat_ssl_port=`/opt/util/parser.sh TOMCAT_SSL_PORT $ENV_PROP_FILE`
tomcat_user=`/opt/util/parser.sh TOMCAT_USER $ENV_PROP_FILE`
ajp_port=`/opt/util/parser.sh AJP_PORT $ENV_PROP_FILE`
shut_down_port=`/opt/util/parser.sh SHUT_DOWN_PORT $ENV_PROP_FILE`

##### Functions

# Waiting for the Policy Server service to be ready to register a new trusted host
register_trusted_host()
{
    i=0
    while true; do
        if [ "$i" -gt "$POLICYSERVER_AVAILABILITY_TIME_OUT" ]; then
            exit 1
        fi

        smreghost -i $ps_host -u $admin_reg_name -p $admin_reg_pswd -hn $trusted_host_name -hc $ps_hco_name -o -cf $fips_mode -f $sm_host_file
        if [ $? -eq 0 ]; then
            echo "[*][$(date +"%T")] - smreghost successfully completed..."
            retval=0
            break
        else
            echo "[*][$(date +"%T")] - Unable to register host against Policy Server. Will try again in 10 seconds($i).........."
            i=`expr $i + 10`
            sleep 10
        fi
    done
}

##### Main
#decrypted using ../password-util/passwordDecode.sh
admin_reg_pswd=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $admin_reg_pswd`
source $sps_home/ca_sps_env.sh

echo "[*][$(date +"%T")] - Updating configuration files..."

# changes related to httpd.conf file
sed -i "s|#User <RUN_AS_USER>|User $tomcat_user|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|#LoadModule env_module modules/mod_env.so|LoadModule env_module modules/mod_env.so|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|#PassEnv LD_LIBRARY_PATH|PassEnv LD_LIBRARY_PATH|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<AID>|$sps_home/httpd|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<SERVERHOSTNAME>:<PORT>|$httpd_port|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<PORT>|$httpd_port|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|#Group nobody|Group nobody|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|#LoadModule unixd_module modules/mod_unixd.so|LoadModule unixd_module modules/mod_unixd.so|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<EID>|$sps_home/proxy-engine|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<SERVERADMIN>|$server_admin|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<SERVERNAME>|$server_name|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|TraceEnable on|TraceEnable off|g" $sps_home/httpd/conf/httpd.conf

# changes related to sps-ctl file
sed -i "s|<RUN_AS_USER>|$tomcat_user|g" $sps_home/proxy-engine/sps-ctl
sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/proxy-engine/sps-ctl

# changes related to httpd-ssl.conf file
sed -i "s|<SERVERHOSTNAME>:<SSLPORT>|$httpd_ssl_port|g" $sps_home/httpd/conf/extra/httpd-ssl.conf
sed -i "s|<SSLPORT>|$httpd_ssl_port|g" $sps_home/httpd/conf/extra/httpd-ssl.conf
sed -i "s|<PID>|$sps_home|g" $sps_home/httpd/conf/extra/httpd-ssl.conf
sed -i "s|<FIPSMODEENTRY>|SSLSpsFipsMode $fips_mode|g" $sps_home/httpd/conf/extra/httpd-ssl.conf
sed -i "s|<AID>|$sps_home/httpd|g" $sps_home/httpd/conf/extra/httpd-ssl.conf
sed -i "s|<SERVERADMIN>|$server_admin|g" $sps_home/httpd/conf/extra/httpd-ssl.conf

# To create $sps_home/arcot/odbc/odbc.ini
touch $sps_home/arcot/odbc/odbc.ini
chmod 775 $sps_home/arcot/odbc/odbc.ini

cat << _EOF_ > $sps_home/arcot/odbc/odbc.ini
[ODBC Data Sources] 
CAAdvancedAuthDSN=SiteMinder Policy Server Wire Protocol

[CAAdvancedAuthDSN]
Driver=$sps_home/arcot/lib/libdaproxy.so
HostConfigFile=$sps_home/arcot/conf/SmHostFlow.conf

[ODBC]
Trace=0
DATrace=0
DATraceSettingsFile=$sps_home/arcot/conf/datracesettings.ini
TraceFile=$sps_home/arcot/logs/odbctrace.out
TraceDll=$sps_home/arcot/odbc/lib/NStrc27.so

InstallDir=$sps_home/arcot/odbc/
_EOF_

# To create $sps_home/proxy-engine/conf/defaultagent/WebAgent.conf
touch $WAConf_file
chmod 777 $WAConf_file

cat << _EOF_ >  $WAConf_file
# WebAgent.conf - configuration file for SiteMinder Secure Proxy

LOCALE=en-US
HostConfigFile="$sm_host_file"
AgentConfigObject="$aco"

ServerPath="ServerPath_default"
EnableWebAgent="$enable_WA"
#localconfigfile="$sps_home/proxy-engine/conf/defaultagent/LocalConfig.conf"
LoadPlugin="$sps_home/agentframework/bin/libHttpPlugin.so"
LoadPlugin="$sps_home/agentframework/bin/libSPSPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libSPPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libDisambiguatePlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libOpenIDPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libSessionLinkerPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libOAuthPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libSAMLDataPlugin.so"
#LoadPlugin="$sps_home/agentframework/bin/libCertSessionLinkerPlugin.so"

AgentIdFile="$sps_home/proxy-engine/conf/defaultagent/AgentId.dat"
_EOF_

#changes to server.conf
sed -i 's|$$AJP_PORT|'"$ajp_port"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$SHUT_DOWN_PORT|'"$shut_down_port"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$LOCALHTTPPORT|'"$tomcat_http_port"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$LOCALHTTPSPORT|'"$tomcat_ssl_port"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$CACERTPATH|'"$sps_home/SSL/certs"'|g' $sps_home/proxy-engine/conf/server.conf

sed -i 's|$$CACERTFILENAME|'"$sps_home/SSL/certs/ca-bundle.cert"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$RULESFILE|'"$sps_home/proxy-engine/conf/proxyrules.xml"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$POLICY_SERVER_VERSION|12.5|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$SMINITFILE|'"$WAConf_file"'|g' $sps_home/proxy-engine/conf/server.conf
sed -i 's|$$HOSTNAME|'"$hostname"'|g' $sps_home/proxy-engine/conf/server.conf

if [[ "$enable_fed_gateway" = "yes" || "$enable_fed_gateway" = "YES" ]] ; then
        sed -i 's|enablefederationgateway="no"|enablefederationgateway="yes"|g' $sps_home/proxy-engine/conf/server.conf
fi

#changes to apachectl
sed -i 's|/vobs/3ptysrc/apache/httpd-unix/Release/Apache2|'"$sps_home/httpd"'|g' $sps_home/httpd/bin/apachectl

#changes to tomcat configuration files
sed -i 's|D\:\\\\netscape\\\\server4\\\\https-webserv1\\\\config\\\\WebAgent.conf|'"$WAConf_file"'|g' $sps_home/Tomcat/webapps/affwebservices/WEB-INF/classes/AffWebServices.properties

sed -i 's|SmHostConfPath=|SmHostConfPath='"$sm_host_file"'|g' $sps_home/Tomcat/webapps/chs/WEB-INF/classes/config/chsConfig.properties
sed -i 's|AgentConfigObject=|AgentConfigObject='"$aco"'|g' $sps_home/Tomcat/webapps/chs/WEB-INF/classes/config/chsConfig.properties

sed -i 's|c\:\\\\FWS.log|'"$sps_home/proxy-engine/logs/affwebserv.log"'|g' $sps_home/Tomcat/webapps/affwebservices/WEB-INF/classes/LoggerConfig.properties
sed -i 's|c\:\\\\FWSTrace.log|'"$sps_home/proxy-engine/logs/FWSTrace.log"'|g' $sps_home/Tomcat/webapps/affwebservices/WEB-INF/classes/LoggerConfig.properties
sed -i 's|D\:\\\\program\ files\\\\netegrity\\\\webagent\\\\config\\\\FWSTrace.conf|'"$sps_home/proxy-engine/conf/defaultagent/FederationTrace.conf"'|g' $sps_home/Tomcat/webapps/affwebservices/WEB-INF/classes/LoggerConfig.properties

#modifying server.conf
sed -n '/<Context*/,/<\/Context>/p' $sps_home/proxy-engine/conf/server.conf > /tmp/output.txt
sed -i '1d' /tmp/output.txt
sed -i 's/^/#/' /tmp/output.txt
sed -i '/<Context name*/,/<\/Context>/d' $sps_home/proxy-engine/conf/server.conf
sed -i -e '/<Contexts>/ r /tmp/output.txt' $sps_home/proxy-engine/conf/server.conf
rm -rf /tmp/output.txt

cp $WAConf_file $sps_home/proxy-engine/conf/webservicesagent/WebAgent.conf

echo "[*][$(date +"%T")] - Running dbutil..."
$ARCOT_HOME/bin/dbutil -init $admin_reg_pswd
$ARCOT_HOME/bin/dbutil -pi CAAdvancedAuthDSN $admin_reg_pswd
$ARCOT_HOME/bin/dbutil -pi admin $admin_reg_pswd $admnin_reg_pswd

echo "[*][$(date +"%T")] - Running smreghost..."
# Waiting for the Policy Server service to be ready to register a new trusted host
register_trusted_host
cp $sm_host_file  $ARCOT_HOME/conf/SmHostFlow.conf

#Temporary: wait for the replication to carry the newly create trusted host to the other worker policy serevers.
sleep 30

echo "[*][$(date +"%T")] - Starting Secure Proxy Server service ..."
$sps_home/proxy-engine/sps-ctl start
