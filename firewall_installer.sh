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
  read -p "Would you like to change SSH server to listen on a non-default port? (y/N): " SET_SSH
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


#your home ip address for the firewall to only allow your ip into ssh
#if you do not have an ip at home that stays the same, leave the below value
#if left to be a.b.c.d then the script will ignore it
TEST_IP_ADDRESS=""
YOURIP=""
while [ "$TEST_IP_ADDRESS" = "" ] && [ "$YOURIP" = "" ]; do
  echo "If you wish to limit SSH access to a single IP address enter it here."
  echo "NOTE:  Setting this will secure your server to ONLY allow SSH from this IP address."
  echo "DO NOT set this if you don't have a static IP address to source your SSH sessions to this server from!"
  echo
  read -p "Enter in your source IP address.  (Leave blank if you wish to allow from any IP.) IP Address: " TEST_IP_ADDRESS
### This still doesn't work! ###
#  if [ $(validateIP $TEST_IP_ADDRESS) -eq 0 ]; then
#    YOURIP=$TEST_IP_ADDRESS
#    FIREWALLIP_OK="1"
#    TEST_IP_ADDRESS=""
#  elif [ "$TEST_IP_ADDRESS" = "" ]; then
#    YOURIP="a.b.c.d"
#  fi
### Instead do no checking ###
  if [ "$TEST_IP_ADDRESS" = "" ]; then
    YOURIP="a.b.c.d"
    FIREWALLIP_OK="0"
  else
    YOURIP=$TEST_IP_ADDRESS
    FIREWALLIP_OK="1"
    TEST_IP_ADDRESS=""
  fi
  echo
done

echo $SECTION_SEPARATOR
echo

#ask if wants to upgrade dist
ASK_DIST_UPGRADE="y"
while [ "$ASK_DIST_UPGRADE" = "y" ]; do
  read -p "Would you like to upgrade Linux distributive to latest version? (y/N): " SET_DIST_UPGRADE
  if [[ "$(tr '[:upper:]' '[:lower:]' <<< "$SET_DIST_UPGRADE")" = "y" || "$(tr '[:upper:]' '[:lower:]' <<< "$SET_DIST_UPGRADE")" = "yes" ]]; then
  	SET_DIST_UPGRADE="y"
  	ASK_DIST_UPGRADE="n"
  else
    if [[ "$(tr '[:upper:]' '[:lower:]' <<< "$SET_DIST_UPGRADE")" = "n" || "$(tr '[:upper:]' '[:lower:]' <<< "$SET_DIST_UPGRADE")" = "no" || "$SET_DIST_UPGRADE" = "" ]]; then
    	SET_DIST_UPGRADE="n"
	ASK_DIST_UPGRADE="n"
    fi
  fi
  echo
done

echo "Updating/Installing packages.  This will take a few minutes."

# install which because some distributives can come without it

if [ ! -f /usr/bin/which ] ; then
	apt install which -y >/dev/null 2>/dev/null
	apt-get install which -y >/dev/null 2>/dev/null
	yum install -y which >/dev/null 2>/dev/null
fi

############## update packages ###################
#determine if apt, apt-get or yum
which apt >/dev/null 2>/dev/null
isapt=$?
which yum >/dev/null 2>/dev/null
isyum=$?
which apt-get >/dev/null 2>/dev/null
isaptget=$?

if [ "$isapt" = "0" ]; then
#ubuntu may not have the universe repo turned on, which will make these fail
	#get codename
   name=`lsb_release -sc`
   echo "deb http://us.archive.ubuntu.com/ubuntu/ $name universe" > /etc/apt/sources.list.d/mn-universe.list
   apt update
   if [ "$SET_DIST_UPGRADE" = "y" ]; then
      apt full-upgrade -y
   fi
   apt install ufw -y
   apt install fail2ban -y
   apt install wget -y
   apt install setools -y
   apt install policycoreutils-python-utils -y
fi

#no need to run apt-get if apt already made installation

if [[ "$isaptget" = "0" && "$isapt" != "0" ]]; then
        #get codename
   name=`lsb_release -sc`
   echo "deb http://us.archive.ubuntu.com/ubuntu/ $name universe" > /etc/apt/sources.list.d/mn-universe.list
   apt-get update
   if [ "$SET_DIST_UPGRADE" = "y" ]; then
      apt-get full-upgrade -y
   fi
   apt-get install ufw -y
   apt-get install fail2ban -y
   apt-get install wget -y
   apt-get install setools -y
   apt-get install policycoreutils-python-utils -y
fi

if [ "$isyum" = "0" ]; then
   yum install -y epel-release 
   yum install -y libselinux-utils
   yum install -y ufw
   yum install -y fail2ban
   yum install -y wget
   yum install -y setools
   yum install -y policycoreutils-python
   yum install -y policycoreutils 
   if [ "$SET_DIST_UPGRADE" = "y" ]; then
      yum update -y
   fi
fi


echo $SECTION_SEPARATOR
echo

############## update ssh port ###################
if [ "$CHANGESSH" = "1" ]; then
#look if selinux is on or not, fake the result if it is not

 if [ `getenforce` = "Enforcing" ]
  then
  echo "SElinux appears to be on, good for you."
  echo "updating ssh context to port $SSHD_PORT"
  semanage port -a -t ssh_port_t -p tcp "$SSHD_PORT"
  selinuxenabled=$?
   #small sanity check
  if [ "$selinuxenabled" -eq "0" ]
    then
    #comment out old port
     echo "selinux context modded successfully"
     sed -i "s@Port@#Port@" /etc/ssh/sshd_config
     #add new port to bottom
     echo "Port $SSHD_PORT" >> /etc/ssh/sshd_config
     systemctl restart ssh 2>/dev/null
     systemctl restart sshd 2>/dev/null
     echo "ssh daemon is now running on port $SSHD_PORT , use this from now on for ssh"
   else
     echo "selinux enabled, but unable to mod context, for your own safety, not changing ssh port!"
      sleep 5
   fi
 else 
     #not enforcing actions
     echo "SElinux not enabled, changing ssh port without bells and whistles"
     #comment out old port
     sed -i "s@Port@#Port@" /etc/ssh/sshd_config
     #add new port to bottom
     echo "Port $SSHD_PORT" >> /etc/ssh/sshd_config
     systemctl restart ssh 2>/dev/null
     systemctl restart sshd 2>/dev/null
     echo "ssh daemon is now running on port $SSHD_PORT , use this from now on for ssh"
 fi
fi

echo $SECTION_SEPARATOR
echo

################## setup firewall #################
#enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

#firewall rules
systemctl enable ufw
echo "y" | ufw enable >/dev/null 2>/dev/null 


if [ "$FIREWALLIP_OK" = "1" ]; then
  ufw allow from $YOURIP
else
  #port for ssh opened if user does not have static ip at home.
  ufw allow $SSHD_PORT
fi

#default ports for pirlnode
ufw allow 30303
ufw allow 4001
ufw allow 6588
ufw allow 6589
ufw allow 5001
ufw allow 8080

#allow all outgoing
ufw default allow outgoing

#block everything else incoming
echo "y" | ufw default deny incoming
sleep 1

clear
#show the status
ufw status

echo $SECTION_SEPARATOR
echo
exit 0
