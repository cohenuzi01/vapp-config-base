#!/bin/bash
export CLASSPATH=$CLASSPATH:cacommons.jar
java_output="$(java -cp base64util.jar:cacommons.jar EncodeUTF8AsBase64 $1)"
echo $java_output
