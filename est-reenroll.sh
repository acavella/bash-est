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
__certs=${__dir}/certs

# Global Variables
VERSION="0.0.2"
DETECTED_OS=$(cat /etc/os-release | grep PRETTY_NAME | cut -d '=' -f2- | tr -d '"')

# Script Variables
dtg=$(date '+%s')
cacert="${__certs}/trust.pem"


# User Defined Variables
puburi="https://twsldc205.gray.bah-csfc.lab:443/.well-known/est/eud"
esturi="https://twsldc205.gray.bah-csfc.lab:8443/.well-known/est/eud"
cnvalue=${1}
p12pass=${2}
origp12="${__certs}/${cnvalue}.p12"

######## FUNCTIONS #########
# All operations are built into individual functions for better readibility
# and management.  

show_version() {
    printf "EST-SimpleReenroll version ${VERSION}"
    printf "Bash version ${BASH_VERSION}"
    printf "${DETECTED_OS}"
    exit 0
}

make_temporary_log() {
    # Create a random temporary file for the log
    TEMPLOG=$(mktemp /tmp/est_temp.XXXXXX)
    # Open handle 3 for templog
    # https://stackoverflow.com/questions/18460186/writing-outputs-to-log-file-and-console
    exec 3>${TEMPLOG}
    # Delete templog, but allow for addressing via file handle
    # This lets us write to the log without having a temporary file on the drive, which
    # is meant to be a security measure so there is not a lingering file on the drive during the install process
    rm ${TEMPLOG}
}

copy_to_run_log() {
    # Copy the contents of file descriptor 3 into the log
    cat /proc/$$/fd/3 > "${log}"
    chmod 644 "${log}"
}

get_cacerts() {
    local pre="-----BEGIN PKCS7-----"
    local post="-----END PKCS7-----"
    local tempp7b=$(mktemp /tmp/tmpp7b.XXXXXX)
    local response=$(mktemp /tmp/resp.XXXXXX)

    # Request trust
    curl ${puburi}/cacerts -v -o ${response} -k --tlsv1.2	

    # Build PKCS#7
    echo -e ${pre} > ${tempp7b}
    cat ${response} >> ${tempp7b}
    echo -e ${post} >> ${tempp7b}
    
    # Convert to PEM
    openssl pkcs7 -print_certs -in ${tempp7b} -out ${cacert}

    # Remove temporary files
    rm ${tempp7b}
    rm ${response}
}

reenroll() {
    local pre="-----BEGIN PKCS7-----"
    local post="-----END PKCS7-----"
    local response=$(mktemp /tmp/resp.XXXXXX)
    local tempp7b=$(mktemp /tmp/tmpp7b.XXXXXX)
    local temppem=$(mktemp /tmp/tmppem.XXXXXX)

    # Convert original PKCS#12 to PEM
    openssl pkcs12 -in ${origp12} -out client.pem -clcerts -nodes -password pass:${p12pass}

    # Generate CSR from client PEM
    openssl req -new -subj "/C=US/CN=${cnvalue}" -key client.pem -out req.pem

    # Send CSR and request new PKCS#7
    curl ${esturi}/simplereenroll --cert client.pem -v -o ${response} --cacert ${cacert} --data-binary @req.pem -H "Content-Type: application/pkcs10" --tlsv1.2

    # Build PKCS#7 from response
    echo -e ${pre} > ${tempp7b}
    cat ${response} >> ${tempp7b}
    echo -e ${post} >> ${tempp7b}

    # Convert PKCS#7 to PEM
    openssl pkcs7 -in ${tempp7b} -out ${temppem} -print_certs

    # Build new client PKCS#12
    openssl pkcs12 -export -inkey client.pem -in ${temppem} -name ${cnvalue} -out ${cnvalue}_new.p12 -certfile ${cacert} -password pass:$p12pass

    # Remove temporary files
    rm ${response}
    rm ${tempp7b}
    rm ${temppem}
    rm client.pem
}

main() {
    get_cacerts
    reenroll
}

make_temporary_log
main | tee -a /proc/$$/fd/3
copy_to_run_log

exit 0