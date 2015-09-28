#!/bin/bash


export CLASSPATH=$CLASSPATH:/solution/$CONFIG/../common/password-util/cacommons.jar
java_output="$(java -cp /solution/$CONFIG/../common/password-util/base64util.jar:/solution/$CONFIG/../common/password-util/cacommons.jar DecodeBase64AsUTF8 $1)"
echo $java_output


