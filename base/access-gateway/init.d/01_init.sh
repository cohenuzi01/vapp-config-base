#!/bin/sh
ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties

sps_home=$NETE_SPS_ROOT
instance_name=`/opt/util/parser.sh INSTANCE_NAME $ENV_PROP_FILE`

#rename /opt/CA/secure-proxy/aas to /opt/CA/secure-proxy/arcot|g
mv $sps_home/aas $sps_home/arcot


sed -i 's|$$DTDPATH|'"$sps_home/proxy-engine/conf/dtd/proxyrules.dtd"'|g' $sps_home/proxy-engine/conf/proxyrules.xml
sed -i "s|<SPS_HOME>|$sps_home|g" $sps_home/Tomcat/properties/httpclientlogging.properties


# changes related to ca_sps_env file
sed -i "s|<INSTANCE_NAME>|$instance_name|g" $sps_home/ca_sps_env.sh
sed -i "s|<SPS_JDK_PATH>|$JAVA_HOME|g" $sps_home/ca_sps_env.sh
sed -i "s|<NETE_SPS_ROOT>|$sps_home|g" $sps_home/ca_sps_env.sh
sed -i "s|<ARCOT_HOME>|$sps_home/arcot|g" $sps_home/ca_sps_env.sh

sed -i "s|<NETE_SPS_ROOT>|$sps_home|g" $sps_home/proxy-engine/conf/SmSpsProxyEngine.properties


# changes related to configssl.sh file
sed -i "s|<SPS_JDK_PATH>|$JAVA_HOME|g" $sps_home/httpd/bin/configssl.sh
sed -i "s|<NETE_SPS_ROOT>|$sps_home|g" $sps_home/httpd/bin/configssl.sh
sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/httpd/bin/configssl.sh

sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/proxy-engine/sps-ctl

# changes related to proxyserver.sh file
sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/proxy-engine/proxyserver.sh
sed -i "s|<ARCOT_HOME>|$sps_home/arcot|g" $sps_home/proxy-engine/proxyserver.sh
sed -i "s|<JAVA_HOME>|$JAVA_HOME|g" $sps_home/proxy-engine/proxyserver.sh
sed -i "s|<TOMCAT_HOME>|$sps_home/Tomcat|g" $sps_home/proxy-engine/proxyserver.sh

sed -i "s|/vobs/3ptysrc/apache/httpd-unix/Release/Apache2/lib|$sps_home/httpd/lib:$sps_home/SSL/lib|g" $sps_home/httpd/bin/envvars-std
sed -i "s|/vobs/3ptysrc/apache/httpd-unix/Release/Apache2|$sps_home/httpd|g" $sps_home/httpd/bin/envvars-std


sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/SSL/bin/EncryptUtil.sh
sed -i "s|<SPS_JDK_PATH>|$JAVA_HOME/Tomcat|g" $sps_home/SSL/bin/EncryptUtil.sh

sed -i "s|/vobs/3ptysrc/apache/httpd-unix/Release/Apache2/lib|$sps_home/httpd/lib:$sps_home/SSL/lib:$sps_home/agentframework/$bin|g" $sps_home/httpd/bin/envvars
sed -i "s|/vobs/3ptysrc/apache/httpd-unix/Release/Apache2|$sps_home/httpd|g" $sps_home/httpd/bin/envvars

sed -i "s|<PROXY_HOME>|$sps_home|g" $sps_home/proxy-engine/bin/GenerateSSLConfig.sh


# changes related to httpd.conf file
sed -i "s|#LoadModule unixd_module|LoadModule unixd_module|g" $sps_home/httpd/conf/httpd.conf
sed -i "s|<EXE>||g" $sps_home/httpd/conf/httpd.conf


sed -i 's|$$PROXY_RULES_DTD\$\$|'"$sps_home/proxy-engine/conf/dtd/proxyrules.dtd"'|g' $sps_home/proxy-engine/examples/proxyrules/*

#changes to apachectl
sed -i 's|$HTTPD|$HTTPD -d '"$sps_home/httpd"'|g' $sps_home/httpd/bin/apachectl

echo $JAVA_HOME

#changes to configssl.sh
sed -i 's|<SPS_JDK_PATH>|$JAVA_HOME|g' $sps_home/httpd/bin/configssl.sh
sed -i 's|<PROXY_HOME>|$sps_home|g' $sps_home/httpd/bin/configssl.sh
sed -i 's|<NETE_SPS_ROOT>|$sps_home|g' $sps_home/httpd/bin/configssl.sh

#changes to SmSpsProxyEngine.properties
sed -i 's|<NETE_SPS_ROOT>|$sps_home|g' $sps_home/proxy-engine/conf/SmSpsProxyEngine.properties

#changes to GenerateSSLConfig.sh
sed -i 's|<PROXY_HOME>|$sps_home|g' $sps_home/proxy-engine/bin/GenerateSSLConfig.sh


#extracting application wars into tomcat

mkdir -p $sps_home/Tomcat/webapps/uiapp 
cd $sps_home/Tomcat/webapps/uiapp
jar xvf $sps_home/Tomcat/webapps/uiapp.war

mkdir -p $sps_home/Tomcat/webapps/authapp 
cd $sps_home/Tomcat/webapps/authapp
jar xvf $sps_home/Tomcat/webapps/authapp.war

mkdir -p $sps_home/Tomcat/webapps/aaloginservice 
cd $sps_home/Tomcat/webapps/aaloginservice
jar xvf $sps_home/Tomcat/webapps/aaloginservice.war


#mkdir -p $ps_home/Tomcat/webapps/proxyui
cd $sps_home/Tomcat/webapps/proxyui
jar xvf $sps_home/Tomcat/webapps/proxyui/proxyui.war


#Temporary fix for entropy issue. Will be removed/modified once alternative approach is confirmed.
mv /dev/random /dev/origrandom
ln -s /dev/urandom /dev/random