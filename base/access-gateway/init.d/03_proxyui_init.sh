#!/bin/bash

ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties

sm_host_file=`/opt/util/parser.sh SM_HOST_FILE $ENV_PROP_FILE`
aco_name=`/opt/util/parser.sh AGENT_CONFIG_OBJ $ENV_PROP_FILE`
agent_name=`/opt/util/parser.sh AGENT_NAME $ENV_PROP_FILE`
admin_reg_name=`/opt/util/parser.sh ADMIN_REG_NAME $ENV_PROP_FILE`
admin_reg_pswd=`/opt/util/parser.sh ADMIN_REG_PASSWORD $ENV_PROP_FILE`

#decrypted using ../password-util/passwordDecode.sh
admin_reg_pswd=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $admin_reg_pswd`

JRE_HOME=$JAVA_HOME
export JRE_HOME


source $NETE_SPS_ROOT/ca_sps_env.sh

PROXYUI_HOME=$NETE_SPS_ROOT/Tomcat/webapps/proxyui
export PROXYUI_HOME

TOMCAT_LIB=$NETE_SPS_ROOT/Tomcat/lib
export TOMCAT_LIB

CLASSPATH=$JRE_HOME/lib:$PROXYUI_HOME/WEB-INF/lib/configtool.jar:$PROXYUI_HOME/WEB-INF/classes:$TOMCAT_LIB/smjavaagentapi.jar:$PROXYUI_HOME/WEB-INF/lib/smjavasdk2.jar:$PROXYUI_HOME/WEB-INF/lib/log4j-1.2.8.jar:$PROXYUI_HOME/WEB-INF/lib/log4j-1.2.8.jar:$TOMCAT_LIB/smi18n.jar:$PROXYUI_HOME/WEB-INF/lib/smadminapi.jar:$PROXYUI_HOME/WEB-INF/lib/smadminapitools.jar:$PROXYUI_HOME/WEB-INF/lib/smrpc.jar
export CLASSPATH

echo $CLASSPATH

PATH=$PATH:$NETE_SPS_ROOT/agentframework/bin
export PATH

echo $sm_host_file
echo $aco_name
echo $agent_name
echo $admin_reg_name
echo $admin_reg_pswd


echo "initializing proxy UI..."

$JRE_HOME/bin/java com/ca/sps/policyconfigtool/SilentCreatePolicy $admin_reg_name $admin_reg_pswd $agent_name $aco_name $sm_host_file
