#!/usr/bin/env bash

# est-reenroll: Client side script to perform EST simple reenroll request
# Version 0.0.1
# 2022-08-05 Tony Cavella (cavella_tony@bah.com)
# https://github.boozallencsn.com/csfc-lab/est-simplereenroll

# -e option instructs bash to immediately exit if any command [1] has a non-zero exit status
# -u option instructs bash to exit on unset variables (useful for debugging)
set -e
set -u

######## VARIABLES #########

# Base directories
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__certs=${__dir}/certs)

# Global Variables
VERSION="0.0.1"
DETECTED_OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2- | tr -d '"')

# Script Variables
dtg=$(date '+%s')
cacert="${__certs}/trust.pem"


# User Defined Variables
capuburi="https://twsldc205.gray.bah-csfc.lab:443/.well-known/est/ca7/"
cainturi="https://twsldc205.gray.bah-csfc.lab:8443/.well-known/est/ca7/"
cnvalue="DemoCN"
origp12="${__certs}/${cnvalue}.p12"
p12pass="YourPassword"


# Load variables from external config
#source ${__dir}/est.conf

######## FUNCTIONS #########
# All operations are built into individual functions for better readibility
# and management.  

show_version() {
    printf "EST-SimpleReenroll version ${VERSION}"
    printf "Bash  version ${BASH_VERSION}"
    printf "${DETECTED_OS}"
    exit 0
}

get_cacerts() {
    curl --insecure ${capuburi}/cacerts -v -o ${cacert}
}

reenroll() {
    openssl pkcs12 -in ${origp12} -out client.pem -nodes -password pass:${p12pass}
    openssl pkcs12 -in ${origp12} -out key.pem -nodes -password pass:${p12pass}
    openssl req -new -subj "/C=US/CN=${cnvalue}" -key key.pem -out req.pem
    curl ${cainturi}/simplereenroll --cert client.pem -v -o output.p7b --cacert ${cacert} --data-binary @req.pem -H "Content-Type: application/pkcs10" --tlsv1.2
    openssl pkcs7 -in output.p7b -inform DER -out result.pem -print_certs
    openssl pkcs12 -export -inkey key.pem -in result.pem -name ${cnvalue} -out ${cnvalue}_new.p12 -password pass:$p12pass
}

clean() {
    rm -rf key.pem
    rm -rf client.pem
    rm -rf result.pem
    rm -rf output.p7b
}

get_cacerts
reenroll
clean
exit 0
    
