#!/bin/bash

SECTION_SEPARATOR="========================================="
ENV_PATH=/etc/pirlnode-content-env
DOWNLOAD_LINK_PREMIUM="https://git.pirl.io/community/pirl/uploads/9f6b22ff763e01353648202bb3718e74/pirl-linux-amd64-v5-masternode-content-hulk"
DOWNLOAD_LINK_MARLIN="https://git.pirl.io/community/pirl/uploads/7b44acaa183a620bd1e57c1663ee9b72/marlin-v5-masternode-content-hulk"
PREMIUM_PATH=/usr/local/bin/pirl-content-core
MARLIN_PATH=/usr/local/bin/pirl-content-marlin

echo $SECTION_SEPARATOR
echo

## https://poseidon.pirl.io/accounts/masternodes-list-private/
MASTERNODE=""
echo "Copy/Paste in the MN token.  It can be found at https://poseidon.pirl.io/accounts/masternodes-list-private/"
echo "Or leave it blank if you already have it written in $ENV_PATH and want no change"
echo
read -p 'Enter MN token:' MASTERNODE
echo

if [[ -f $ENV_PATH && "$MASTERNODE" = "" ]]; then
	echo "Leaving MN token as is"
	echo
 else
 	if [[ ! -f $ENV_PATH && "$MASTERNODE" = "" ]]; then
		echo "$ENV_PATH file for tokens doesn't exist"
	fi
	echo
 	rm -f $ENV_PATH
	while [ "$MASTERNODE" = "" ]; do
		echo "Copy/Paste in the MN token.  It can be found at https://poseidon.pirl.io/accounts/masternodes-list-private/"
		read -p 'Enter MN token:' MASTERNODE
		echo
	done
 fi

echo $SECTION_SEPARATOR
echo

## https://poseidon.pirl.io/accounts/settings/
TOKEN=""
if [ "$MASTERNODE" != "" ]; then
	while [ "$TOKEN" = "" ]; do
	  echo "Copy/Paste in your POSEIDON account's token.  It can be found at https://poseidon.pirl.io/accounts/settings/"
	  echo
	  read -p 'Enter TOKEN:' TOKEN
	  echo
	done
 else
	echo "Leaving POSEIDON token as is"
 fi
echo

echo $SECTION_SEPARATOR
echo

#username you want the service to run as, if you want it to run as root, leave root
#if you want it to run as pirl put in pirl. no spaces allowed, and all lower case please.
#this user will not be used as a login user, so no password will be set.
read -p "What username should the PIRL Masternode run as? (root, pirl, or leave blank to run as current user): " TEST_RUNAS_USER
if [ "$TEST_RUNAS_USER" = "" ]; then
  RUNAS_USER=`logname`
else
  RUNAS_USER=$TEST_RUNAS_USER
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

# download wget before pirl installation

if [ ! -f /usr/bin/wget ] ; then
	echo "Installing wget..."
	apt install wget -y >/dev/null 2>/dev/null
	apt-get install wget -y >/dev/null 2>/dev/null
	yum install -y wget >/dev/null 2>/dev/null
fi

############# grab the node binary and chmod ############################
###the chain will end up being stored on this users home dir, at /home/username/.pirl/

##make sure its not running if for reason the service is already there, do clean up incase it was run again  for some reason
echo "Stopping pirlnode, if it is running."
systemctl stop pirlnode 2>/dev/null 1>/dev/null
if [ -e $PREMIUM_PATH ]; then
  echo "Cleaning up previous PIRL installation."
  rm -f $PREMIUM_PATH 2>/dev/null
fi
#get pirl node
echo "downloading latest PIRL Masternode"
wget -O $PREMIUM_PATH $DOWNLOAD_LINK_PREMIUM
downloadresult=$?
chmod 0755 $PREMIUM_PATH
chmodresult=$?

#double check download and perms
if [ "$downloadresult" != "0" ] || [ "$chmodresult" != "0" ]; then
  echo "error happened downloading the node from"
  echo $DOWNLOAD_LINK_PREMIUM
  echo "or trying to chmod it to 0755 at location"
  echo $PREMIUM_PATH
  exit 6
fi

echo $SECTION_SEPARATOR
echo

############# grab the marlin-node binary and chmod ############################
###the chain will end up being stored on this users home dir, at /home/username/.pirl/

##make sure its not running if for reason the service is already there, do clean up incase it was run again  for some reason
echo "Stopping pirlnode, if it is running."
systemctl stop pirlmarlin 2>/dev/null 1>/dev/null
if [ -e $MARLIN_PATH ]; then
  echo "Cleaning up previous PIRL installation."
  rm -f $MARLIN_PATH 2>/dev/null
fi
#get pirl-marlin node
echo "downloading latest PIRL Marlin"
wget -O $MARLIN_PATH $DOWNLOAD_LINK_MARLIN
downloadresult=$?
chmod 0755 $MARLIN_PATH
chmodresult=$?

#double check download and perms
if [ "$downloadresult" != "0" ] || [ "$chmodresult" != "0" ]; then
  echo "error happened downloading the node from"
  echo $DOWNLOAD_LINK_MARLIN
  echo "or trying to chmod it to 0755 at location"
  echo $MARLIN_PATH
  exit 6
fi

echo $SECTION_SEPARATOR
echo

############ populate files for systemd service #########
echo "Create pirl-node systemd unit file, install, and start."
echo "[Unit]
Description=Pirl Master Node
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=$ENV_PATH

Type=simple
User=$RUNAS_USER
Group=$RUNAS_USER
RestartSec=30s
ExecStart=$PREMIUM_PATH --rpc --ws
Restart=always

[Install]
WantedBy=default.target
">/etc/systemd/system/pirlnode-content.service

if [[ -f $ENV_PATH ]]; then
	echo "Tokens haven't been changed"
else
echo "MASTERNODE=\"$MASTERNODE\"
TOKEN=\"$TOKEN\"">$ENV_PATH
echo "Successfully created $ENV_PATH with new tokens"
fi

###reload in case it was there before, and now could be changed
systemctl daemon-reload

####enable the node
systemctl enable pirlnode-content

###start the node
systemctl restart pirlnode-content


############ populate files for systemd-marlin service #########
echo "Create pirl-marlin systemd unit file, install, and start."
echo "[Unit]
Description=Pirl Client -- marlin content service
After=network.target pirlnode-content.service
Wants=network.target pirlnode-content.service

[Service]
EnvironmentFile=$ENV_PATH

Type=simple
User=$RUNAS_USER
Group=$RUNAS_USER
RestartSec=30s
ExecStartPre=/bin/sleep 5
ExecStart=$MARLIN_PATH daemon
Restart=always

[Install]
WantedBy=default.target
">/etc/systemd/system/pirlmarlin-content.service

if [[ ! -d $homedir/.marlin/ || ! -f $homedir/.marlin/config ]]; then
	rm -rf $homedir/.marlin/
	echo "Wait 5 seconds for pirlnode to run before initializing marlin"
	echo -ne ".\r"
	sleep 1
	echo -ne "..\r"
	sleep 1
	echo -ne "...\r"
	sleep 1
	echo -ne "....\r"
	sleep 1
	echo -ne ".....\r"
	sleep 1
	echo -ne "\r\033[K"
	su -c "$MARLIN_PATH init 1>/dev/null" $RUNAS_USER -s /bin/bash
	chown -R $RUNAS_USER:$RUNAS_USER $homedir/.marlin/
	
	if [ -f $homedir/.marlin/config ]; then
		echo "Pirl marlin successfully initialized"
 	else
  		echo "Something went wrong with initializing marlin folder"
		echo "Please run '$MARLIN_PATH init' manually after installation"
	fi
fi

###reload in case it was there before, and now could be changed
systemctl daemon-reload

####enable the node
systemctl enable pirlmarlin-content

###start the node
systemctl restart pirlmarlin-content


echo $SECTION_SEPARATOR
echo

#ask if wants to install firewall and change ssh
ASK_FIREWALL="y"
while [ "$ASK_FIREWALL" = "y" ]; do
  read -p "Would you like to install and configure firewall and change SSH settings? (y/N): " SET_FIREWALL
  if [[ "$SET_FIREWALL" = "y" || "$SET_FIREWALL" = "Y" ]]; then
  	SET_FIREWALL="y"
  	ASK_FIREWALL="n"
  else
    if [[ "$SET_FIREWALL" = "n" || "$SET_FIREWALL" = "N" || "$SET_FIREWALL" = "" ]]; then
    	SET_FIREWALL="n"
	ASK_FIREWALL="n"
    fi
  fi
  echo
done

if [ "$SET_FIREWALL" = "y" ]; then
   bash ./firewall_installer.sh
fi

echo "All done!"
echo
echo "Commands you can run now:"
echo "Check PIRL-node status with: 'systemctl status pirlnode-content'"
echo "Check PIRL-marlin status with: 'systemctl status pirlmarlin-content'"
echo "Watch PIRL-node system logs with: 'journalctl -f -u pirlnode-content'"
echo "Watch PIRL-marlin system logs with: 'journalctl -f -u pirlmarlin-content'"
if [ "$SET_FIREWALL" = "y" ]; then
   echo "Check firewall status with: 'ufw status'"
fi

exit 0
