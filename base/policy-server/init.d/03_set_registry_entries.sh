#!/bin/bash

echo "[*] Create default objects: starting"

ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties
OBJECT_FILE=/solution/$CONFIG/object/SMPS_Objects.xml

ps_home=`/opt/util/parser.sh nete_ps_root $ENV_PROP_FILE`
shared_key=`/opt/util/parser.sh nete_shared_key $ENV_PROP_FILE`
ldap_ip=`/opt/util/parser.sh POLICY_STORE_HOST $ENV_PROP_FILE`
ldap_port=`/opt/util/parser.sh POLICY_STORE_PORT $ENV_PROP_FILE`
ldap_userdn=`/opt/util/parser.sh POLICY_STORE_USER_DN $ENV_PROP_FILE`
ldap_password=`/opt/util/parser.sh POLICY_STORE_USER_PASSWORD $ENV_PROP_FILE`
ldap_rootdn=`/opt/util/parser.sh POLICY_STORE_ROOT_DN $ENV_PROP_FILE`
ldap_ssl=`/opt/util/parser.sh POLICY_STORE_SSL_ENABLED $ENV_PROP_FILE`
ldap_fips_mode=`/opt/util/parser.sh nete_fips_mode $ENV_PROP_FILE`
su_password=`/opt/util/parser.sh nete_su_password $ENV_PROP_FILE`

#decrypted using ../password-util/passwordDecode.sh
su_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $su_password`
shared_key=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $shared_key`
ldap_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $ldap_password`

set CA_SM_PS_FIPS140=$ldap_fips_mode

source $NETE_PS_ROOT/ca_ps_env.ksh

echo "[*] Starting smreg operations"

/opt/CA/tmp/smreg LoadRegKeys "$ps_home" "" "EN"
/opt/CA/tmp/smreg TestCryptoConfig "$shared_key"  "0" "" "" ""
/opt/CA/tmp/smreg SetCryptoConfig "$shared_key"  "0" "" "" ""
/opt/CA/tmp/smreg $DASH_PIN$ LoadInstallKey -123
/opt/CA/tmp/smreg -key $shared_key

echo "[*] Finished executing smreg"

echo "[*] Starting smldapsetup"

echo "NETE_PS_ROOT=$NETE_PS_ROOT"
echo "CAPKIHOME=$CAPKIHOME"
echo "POLICY_STORE_HOST=$ldap_ip"
echo "POLICY_STORE_PORT=$ldap_port"
echo "POLICY_STORE_USER_DN=$ldap_userdn"
echo "POLICY_STORE_ROOT_DN=$ldap_rootdn"

$NETE_PS_ROOT/bin/smldapsetup switch

$NETE_PS_ROOT/bin/smldapsetup reg -h$ldap_ip -p$ldap_port -d$ldap_userdn -w$ldap_password -r$ldap_rootdn -ssl$ldap_ssl

echo "[*] Finished smldapsetup"

echo "[*] Starting set super user password"
TIME_OUT=500
i=0

while true; do
    if [ "$i" -gt "$TIME_OUT" ]; then
        exit 1
    fi

    /opt/CA/tmp/smreg -su $su_password
    if [ $? -eq 0 ]; then
        echo "Finished set super user password."
        retval=0
        break
    else
        echo "Unable to set super user password...."
        i=`expr $i + 10`
        echo "Sleeping for 10 secs and re trying.........."
        sleep 10
    fi
done

#/opt/CA/tmp/smreg -su $su_password

#echo "[*] Finished set super user password"

echo "[*] Starting XPSDDinstall"
# TODO: Do not import schema if it is already there

$NETE_PS_ROOT/bin/XPSDDInstall $NETE_PS_ROOT/xps/dd/SmMaster.xdd

echo "[*] FinishedXPSDDInstall"

echo "[*] Starting XPS Reg client"

$NETE_PS_ROOT/bin/XPSRegClient siteminder:$su_password -adminui-setup -t 1440

echo "[*] Finished XPS Reg client..."

echo "[*] Starting import default objects"
# TODO: Do not import data if it is already there

$NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/smpolicy.xml -npass

$NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/ampolicy.xml -npass

$NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/fedpolicy-12.5.xml -npass

$NETE_PS_ROOT/bin/XPSImport $OBJECT_FILE -npass

$NETE_PS_ROOT/bin/XPSImport /solution/$CONFIG/object/proxyui_objects.xml -npass

echo "[*] Finished import default objects"


echo "[*] Create default objects: complete"
