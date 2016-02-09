#!/bin/bash

# 03_set_registry_entries - This script initializes the Policy Server configuration files. 
# If this script runs on a master policy server, it will initialize the policy store (in case it's not already initialized).  
# If this script runs on a worker policy server, it will wait for the  policy store to be initialized before starting. 

##### Constants
POLICY_STORE_VERSION="r12.52 sp1"
POLICY_STORE_VERIFICATION_ATTRIBUTE=CA.SM::AuthScheme.SupportsValidateIdentity
ENV_PROP_FILE=/solution/$CONFIG/data/environment.properties
OBJECT_FILES_FOLDER=/solution/$CONFIG/object

STORE_AVAILABILITY_TIME_OUT=500
STORE_INITIALIZATION_TIME_OUT=600

echo "[*][$(date +"%T")] - Create default objects: starting"
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

POLICY_STORE_INITIALIZATION_COMPLETE_INDICATOR="ou=SSOInitialized"
POLICY_STORE_INITIALIZATION_COMPLETE_INDICATOR_DN="$POLICY_STORE_INITIALIZATION_COMPLETE_INDICATOR, $ldap_rootdn"

#decrypted using ../password-util/passwordDecode.sh
su_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $su_password`
shared_key=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $shared_key`
ldap_password=`/solution/$CONFIG/../common/password-util/passwordDecode.sh $ldap_password`

set CA_SM_PS_FIPS140=$ldap_fips_mode

##### Functions
 
wait_for_policy_store_to_start()
{
    i=0
    # Waiting for the Policy Store service to be ready
    while true; do
        if [ "$i" -gt "$STORE_AVAILABILITY_TIME_OUT" ]; then
            echo "[*][$(date +"%T")] - A timeout was reached ($STORE_AVAILABILITY_TIME_OUT seconds) while waiting for the policy store to be available."
            exit 1
        fi

        $NETE_PS_ROOT/bin/smldapsetup status | grep -q "Error"
        if [ $? -ne 0 ]; then
            echo "[*][$(date +"%T")] - Policy store is up and running."
            retval=0
            break
        else
            echo "[*][$(date +"%T")] - Unable to connect to the policy store. Waiting for the policy-store to be available ($i).........."
            i=`expr $i + 10`
            sleep 10
        fi
    done
} 

initialize_policy_store()
{ 
    echo "[*][$(date +"%T")] - Initializing policy store:"
    echo "[*][$(date +"%T")] - Setting SiteMinder's super user password."

    /opt/CA/tmp/smreg -su $su_password

    #echo "[*][$(date +"%T")] - Finished set super user password"
    echo "[*][$(date +"%T")] - Starting XPSDDinstall"

    $NETE_PS_ROOT/bin/XPSDDInstall $NETE_PS_ROOT/xps/dd/SmMaster.xdd

    echo "[*][$(date +"%T")] - FinishedXPSDDInstall"

    echo "[*][$(date +"%T")] - Starting import default objects"
    
    $NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/smpolicy.xml -npass
    $NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/ampolicy.xml -npass
    $NETE_PS_ROOT/bin/XPSImport $NETE_PS_ROOT/db/fedpolicy-12.5.xml -npass

#   Will xps import all the xml files in the $OBJECT_FILES_FOLDER.
#   These include SMPS_Objects.xml and proxyui_objects.xml that create
#   objects that are required for the Secure Proxy deployment as well as any other customer specific file
    for filename in $OBJECT_FILES_FOLDER/*.xml; do
        echo Using XPSImport to import "$filename"...
        $NETE_PS_ROOT/bin/XPSImport "$filename"  -npass -fo  
    done

    echo "[*][$(date +"%T")] - Finished import default objects"

    echo "[*][$(date +"%T")] - Starting XPS Reg client"

    $NETE_PS_ROOT/bin/XPSRegClient siteminder:$su_password -adminui-setup -t 1440

    echo "[*][$(date +"%T")] - Finished XPS Reg client..."
    
    #Creating an indicator object in the store to mark the completion of store initialization
    echo version: 1 >SSOInitialized.ldif
    echo dn: $POLICY_STORE_INITIALIZATION_COMPLETE_INDICATOR_DN >>SSOInitialized.ldif
    echo objectClass: organizationalUnit >>SSOInitialized.ldif
    echo objectClass: top >>SSOInitialized.ldif
    echo ou: SSOInitialized >>SSOInitialized.ldif
    echo description: SSO version $POLICY_STORE_VERSION >>SSOInitialized.ldif
    smldapmodify  -h $ldap_ip -p $ldap_port -D $ldap_userdn -w $ldap_password -a -f SSOInitialized.ldif
    echo "[*][$(date +"%T")] - Policy Store initialization completed"
}

wait_for_policy_store_to_be_initialized()
{
    i=0
    echo "[*][$(date +"%T")] - Waiting for the Policy Store to be initialized by the Master Policy Server"
    while true; do
        if [ "$i" -gt "$STORE_INITIALIZATION_TIME_OUT" ]; then
        echo "[*][$(date +"%T")] - A timeout was reached ($STORE_AVAILABILITY_TIME_OUT seconds) while waiting for the policy store to be initialized."
        exit 1
        fi
        ldapsearch -b "$POLICY_STORE_INITIALIZATION_COMPLETE_INDICATOR_DN" -h $ldap_ip -p $ldap_port -D $ldap_userdn -w $ldap_password -R -1 -s base "objectClass=*" description 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[*][$(date +"%T")] - Policy store is initialized and ready."
            retval=0
            break
        else
            echo "[*][$(date +"%T")] - Waiting for the policy store to be initialized ($i)...."
            i=`expr $i + 10`
            sleep 10
        fi
    done
 }
 
 ##### Main
source $NETE_PS_ROOT/ca_ps_env.ksh

echo "[*][$(date +"%T")] - Starting smreg operations"
/opt/CA/tmp/smreg LoadRegKeys "$ps_home" "" "EN"
/opt/CA/tmp/smreg TestCryptoConfig "$shared_key"  "0" "" "" ""
/opt/CA/tmp/smreg SetCryptoConfig "$shared_key"  "0" "" "" ""
/opt/CA/tmp/smreg $DASH_PIN$ LoadInstallKey -123
/opt/CA/tmp/smreg -key $shared_key
echo "[*][$(date +"%T")] - Finished executing smreg"

echo "[*][$(date +"%T")] - Configure Policy Server to point at the policy store."
cat << _EOM_
    NETE_PS_ROOT=$NETE_PS_ROOT
    CAPKIHOME=$CAPKIHOME
    POLICY_STORE_HOST=$ldap_ip
    POLICY_STORE_PORT=$ldap_port
    POLICY_STORE_USER_DN=$ldap_userdn
    POLICY_STORE_ROOT_DN=$ldap_rootdn
_EOM_

$NETE_PS_ROOT/bin/smldapsetup switch
$NETE_PS_ROOT/bin/smldapsetup reg -h$ldap_ip -p$ldap_port -d$ldap_userdn -w$ldap_password -r$ldap_rootdn -ssl$ldap_ssl

echo "[*][$(date +"%T")] - Checking if the policy store is up and running..."
wait_for_policy_store_to_start

echo "[*][$(date +"%T")] - Policy Server is running as $ROLE."
if [ "$ROLE" == "master" ]; then
    #Checking whether the scheme is of the right version by checking the existence of a certain attribute
    echo r> replay.cmd
    echo $POLICY_STORE_VERIFICATION_ATTRIBUTE>> replay.cmd
    $NETE_PS_ROOT/bin/XPSDictionary <replay.cmd 2>/dev/null | grep "Matches Attribute"
    if [ $? -ne 0 ]; then
        echo "[*][$(date +"%T")] - Policy store is not initialized or does not run an updated schema."
        initialize_policy_store
    else
        echo "[*][$(date +"%T")] - Policy store is initialized and running with the latest schema"
    fi
else #Worker Policy Server will wait for the Policy Store to be initialized by the "Master Policy Server"
    wait_for_policy_store_to_be_initialized
    echo SM > replay.cmd
    echo CA.SM::\$EnableKeyGeneration >> replay.cmd
    
    $NETE_PS_ROOT/bin/XPSConfig <replay.cmd 2>/dev/null |grep -A 20 -F "PARAMETER MENU***********************************CA.SM::$EnableKeyGeneration" |grep "Current Value:  [ \t]* \"TRUE\""
    if [ $? -eq 0 ]; then
        echo "[*][$(date +"%T")] - Configuring Policy Server not to generate agent keys."
        echo C >>replay.cmd
        $NETE_PS_ROOT/bin/XPSConfig <replay.cmd 2>/dev/null |grep -A 20 -F "PARAMETER MENU***********************************CA.SM::$EnableKeyGeneration" |grep "Pending Value:  [ \t]* \"FALSE\""
    else
      echo "[*][$(date +"%T")] - Policy Server is set not to generate agent keys."
    fi
fi

