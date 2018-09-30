#!/bin/bash

SECTION_SEPARATOR="========================================="

function validateIP()
 {
         local ip=$1
         local stat=1
         if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                OIFS=$IFS
                IFS='.'
                ip=($ip)
                IFS=$OIFS
                [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
                && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
                stat=$?
        fi
        return $stat
}


###((((( highly recommended you change the port SSH server listens on! ))))))###
TEST_SSH_PORT=22  #(recommended range is 1025-65535)
ASK_SSH='y'
#DO NOT USE PORT 30303
while [ "$ASK_SSH" = "y" ]; do
  #clear
  read -p "Would you like to change SSH server to listen on a non-default port? (y/n): " SET_SSH
  if [ "$SET_SSH" = "y" ]; then
    read -p "What port should SSH server listen on? (Options: 1024-65535 but not 30303): " TEST_SSH_PORT
  fi
  if [ $TEST_SSH_PORT -eq 22 ] || ([ $TEST_SSH_PORT -ne 30303 ] && [ $TEST_SSH_PORT -gt 1023 ] && [ $TEST_SSH_PORT -lt 65536 ]); then
    ASK_SSH='n'
    SSHD_PORT=$TEST_SSH_PORT
  else
    echo "SSH cannot run on port 30303, nor be on a port less than 1024, nor be on a port higher than 65535.  Try again."
    TEST_SSH_PORT=22
  fi
  echo
done

#check sshd port
CHANGESSH="0"
if [ "$SSHD_PORT" != "22" ]; then
  CHANGESSH="1"
fi

echo $SECTION_SEPARATOR
echo
