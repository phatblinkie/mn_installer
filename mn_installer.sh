#!/usr/bin/env bash

SECTION_SEPARATOR="#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#"

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

echo $SECTION_SEPARATOR

## https://poseidon.pirl.io/accounts/masternodes-list-private/
MASTERNODE=""
while [ "$MASTERNODE" = "" ]; do
  echo "Copy/Paste in the MN token.  It can be found at https://poseidon.pirl.io/accounts/masternodes-list-private/"
  read -p 'Enter MN token:' MASTERNODE
  echo
done

echo $SECTION_SEPARATOR

## https://poseidon.pirl.io/accounts/settings/
TOKEN=""
while [ "$TOKEN" = "" ]; do
  echo "Copy/Paste in your POSEIDON account's token.  It can be found at https://poseidon.pirl.io/accounts/settings/"
  read -p 'Enter TOKEN:' TOKEN
  echo
done

echo $SECTION_SEPARATOR

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

#your home ip address for the firewall to only allow your ip into ssh
#if you do not have an ip at home that stays the same, leave the below value
#if left to be a.b.c.d then the script will ignore it
TEST_IP_ADDRESS=""
YOURIP=""
while [ "$TEST_IP_ADDRESS" = "" ] && [ "$YOURIP" = "" ]; do
  echo "If you wish to limit SSH access to a single IP address enter it here."
  echo "NOTE:  Setting this will secure your server to ONLY allow SSH from this IP address."
  echo "DO NOT set this if you don't have a static IP address to source your SSH sessions to this server from!"
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

#username you want the service to run as, if you want it to run as root, leave root
#if you want it to run as pirl put in pirl. no spaces allowed, and all lower case please.
#this user will not be used as a login user, so no password will be set.
read -p "What username should the PIRL Masternode run as? (root, pirl, or leave blank to run as current user): " RUNAS_USER
if [ "$TEST_RUNAS_USER" = "" ]; then
  RUNAS_USER=`logname`
fi

#check if username already exists,(if not we will make it later)
#if so, does it have a valid home dir for chain storage?
CREATEUSERNAME=0
getent passwd $RUNAS_USER > /dev/null
if [ $? -eq 0 ]; then
    echo "User $RUNAS_USER exists"
    homedir=$( getent passwd "$RUNAS_USER" | cut -d: -f6 )
    if [ ! -d $homedir ]; then
      echo "$RUNAS_USER has no home dir, or its not available. exiting."
      exit 4
    fi
 else
   echo "User $RUNAS_USER not found, will create."
   CREATEUSERNAME=1
   sleep 1
fi

#create the user if needed. just a run as user, not a login user, but they must have a home dir for the chain storage
if [ "$CREATEUSERNAME" = "1" ]; then
   getent passwd $RUNAS_USER > /dev/null || useradd -r -m -s /usr/sbin/nologin -c "pirl masternode user" $RUNAS_USER
fi

#make sure its was created
getent passwd $RUNAS_USER > /dev/null
if [ $? -eq 0 ]; then
    echo "User $RUNAS_USER created"
    homedir=$( getent passwd "$RUNAS_USER" | cut -d: -f6 )
    if [ ! -d $homedir ]; then
      echo "New users home dir created as well @ $homedir"
    fi
 else
 echo "user $RUNAS_USER not found, tried to create but failed. stopping"
 exit 4
fi

echo $SECTION_SEPARATOR
echo

############# grab the node binary and chmod ############################
###the chain will end up being stored on this users home dir, at /home/username/.pirl/

##make sure its not running if for reason the service is already there, do clean up incase it was run again  for some reason
echo "Stopping pirlnode, if it is running."
systemctl stop pirlnode 2>/dev/null 1>/dev/null
if [ -e /usr/local/bin/pirl-linux-amd6 ]; then
  echo "Cleaning up previous PIRL installation."
  rm -f /usr/local/bin/pirl-linux-amd64 2>/dev/null
fi
#get pirl node
echo "downloading latest PIRL Masternode"
wget -O /usr/local/bin/pirl-linux-amd64 http://release.pirl.io/downloads/masternode/linux/pirl-linux-amd64
downloadresult=$?
chmod 0755 /usr/local/bin/pirl-linux-amd64
chmodresult=$?

#double check download and perms
if [ "$downloadresult" != "0" ] || [ "$chmodresult" != "0" ]; then
  echo "error happened downloading the node from http://release.pirl.io/downloads/masternode/linux/pirl-linux-amd64"
  echo "or trying to chmod it to 0755 at location /usr/local/bin/pirl-linux-amd64"
  exit 6
fi

echo $SECTION_SEPARATOR
echo

############ populate files for systemd service #########
echo "Create systemd unit file, install, and start."
echo "[Unit]
Description=Pirl Master Node

[Service]
EnvironmentFile=/etc/pirlnode-env

Type=simple
User=$RUNAS_USER
Group=$RUNAS_USER

ExecStart=/usr/local/bin/pirl-linux-amd64
Restart=always

[Install]
WantedBy=default.target
">/etc/systemd/system/pirlnode.service

echo "MASTERNODE=\"$MASTERNODE\"
TOKEN=\"$TOKEN\"
">/etc/pirlnode-env

###reload in case it was there before, and now could be changed
systemctl daemon-reload

####enable the node
systemctl enable pirlnode

###start the node
systemctl start pirlnode

echo $SECTION_SEPARATOR
echo
echo "Updating/Installing packages.  This will take a few minutes."

############## update packages ###################
#determine if apt, apt-get or yum
which apt >/dev/null 2>/dev/null
isapt=$?
which yum >/dev/null 2>/dev/null
isyum=$?
which apt-get >/dev/null 2>/dev/null
isaptget=$?

if [ "$isapt" -eq "0" ]
then 
apt update
apt full-upgrade -y
apt install ufw -y
apt install fail2ban -y
apt install setools policycoreutils-python -y
fi

if [ "$isaptget" -eq "0" ]
then
apt-get update
apt-get dist-upgrade -y
apt-get install ufw -y
apt-get install fail2ban -y
apt-get install setools policycoreutils-python -y
fi

if [ "$isyum" -eq "0" ]
then
yum install -y epel-release
yum update -y
yum install ufw -y
yum install fail2ban -y
yum install setools policycoreutils-python -y
fi



############## update ssh port ###################
if [ "$CHANGESSH" = "1" ]; then
#look if selinux is on or not, fake the result if it is not

 if [ `getenforce` = "Enforcing" ]
  then
  echo "SElinux appears to be on, good for you."
  echo "updating ssh context to port $SSHD_PORT"
  semanage port -a -t ssh_port_t -p tcp $SSHD_PORT
  selinuxenabled = $?
   #small sanity check
  if [ "$selinuxenabled" -eq "0" ]
    then
    #comment out old port
     sed -i "s@Port@#Port@" /etc/ssh/sshd_config
     #add new port to bottom
     echo "Port $SSHD_PORT" >> /etc/ssh/sshd_config
     systemctl restart ssh 2>/dev/null
     systemctl restart sshd 2>/dev/null
     echo "ssh daemon is now running on port $SSHD_PORT , use this from now on for ssh"
  else
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
fi

echo $SECTION_SEPARATOR
echo

################## setup firewall #################
#enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

#firewall rules
systemctl enable ufw
if [ "$FIREWALLIP_OK" = "1" ]; then
  ufw allow from $YOURIP
else
  #port for ssh opened if user does not have static ip at home.
  ufw allow $SSHD_PORT
fi

#default ports for pirlnode
ufw allow 30303

#allow all outgoing
ufw default allow outgoing

#block everything else incoming
echo "y" | ufw default deny incoming
sleep 1
echo "y" | ufw enable

clear
#show the status
ufw status

echo $SECTION_SEPARATOR
echo
echo "all done!"
echo
echo "commands you can run now:"
echo "Check firewall status with: 'ufw status'"
echo "Check PIRL status with: 'systemctl status pirlnode'"
echo "Watch PIRL system logs with: 'journalctl -f -u pirlnode'"

exit 0
