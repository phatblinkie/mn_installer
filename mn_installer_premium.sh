#!/bin/bash

echo "This is for premium or content verion 1.8.27 hulk release"
sleep 5

SECTION_SEPARATOR="========================================="
ENV_PATH=/etc/pirlnode-env

marlin_content_link='https://storage.googleapis.com/pirl-node/pirl-1.8.27-gecko/marlin/marlin-masternode-gecko1_8_27'
marlin_content_md5='870fc5bc8f1c16ae50b168c389f3a743'
marlin_premium_link='https://storage.googleapis.com/pirl-node/pirl-1.8.27-gecko/marlin/marlin-masternode-gecko1_8_27'
marlin_premium_md5='870fc5bc8f1c16ae50b168c389f3a743'
masternode_content_link='https://storage.googleapis.com/pirl-node/pirl-1.8.27-gecko/masternodes/content/pirl-linux-amd64-content'
masternode_content_md5='4cdd976938ee2809b56c28ba14fd5675'
masternode_premium_link='https://storage.googleapis.com/pirl-node/pirl-1.8.27-gecko/masternodes/premium/pirl-linux-amd64-premium'
masternode_premium_md5='848557e760a4f6d575345985be8d033b'

#determine if this is a content node
PS3='Please enter your Masternode type: '
options=("Premium" "Content" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Premium")
            echo "you chose Premium, good choice"
DOWNLOAD_LINK_PIRL=$masternode_premium_link
DOWNLOAD_LINK_MARLIN=$marlin_premium_link
	    break
            ;;
        "Content")
            echo "you chose Content, here we go!"
DOWNLOAD_LINK_PIRL=$masternode_content_link
DOWNLOAD_LINK_MARLIN=$marlin_content_link
	    break
            ;;
        "Quit")
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done



PIRL_PATH=/usr/bin/pirl
MARLIN_PATH=/usr/bin/marlin

#fix previous paths
#if the file is found, then it was previously run, change it
if [ -f /usr/local/bin/pirl-premium-core ] 
  then
    systemctl stop pirlnode
    systemctl disable pirlnode
    sleep 2
    rm -f /usr/local/bin/pirl-premium-core 
    rm -f /etc/systemd/system/pirlnode.service 
    systemctl daemon-reload
 fi
 #if the file is found, then it was previously run, change it
 if [ -f /usr/local/bin/pirl-premium-marlin ] 
  then
    systemctl stop pirlmarlin
    systemctl disable pirlmarlin
    sleep 2
    rm -f /usr/local/bin/pirl-premium-marlin
    rm -f /etc/systemd/system/pirlmarlin.service
    systemctl daemon-reload
 fi 



echo $SECTION_SEPARATOR
echo

## https://poseidon.pirl.io/accounts/masternodes-list-private/
MASTERNODE=""
echo "Copy/Paste in the MN token.  It can be found at https://poseidon.pirl.io/accounts/masternodes-list-private/
It will have hyphens in it, like this marlin_content_linkc0c5dfdd-9ced-4b52-9448-74b66c2a6de0c0c5dfdd-9ced-4b52-9448-74b66c2a6de0"
#no longer using the environment file
#echo "Or leave it blank if you already have it written in $ENV_PATH and want no change"
echo
read -p 'Enter MN token:' MASTERNODE
echo

#if [[ -f $ENV_PATH && "$MASTERNODE" = "" ]]; then
#	echo "Leaving MN token as is"
#	echo
# else
# 	if [[ ! -f $ENV_PATH && "$MASTERNODE" = "" ]]; then
#		echo "$ENV_PATH file for tokens doesn't exist"
#	fi
#	echo
# 	rm -f $ENV_PATH
#	while [ "$MASTERNODE" = "" ]; do
#		echo "Copy/Paste in the MN token.  It can be found at https://poseidon.pirl.io/accounts/masternodes-list-private/"
#		read -p 'Enter MN token:' MASTERNODE
#		echo
#	done
# fi

echo $SECTION_SEPARATOR
echo

## https://poseidon.pirl.io/accounts/settings/
TOKEN=""
#if [ "$MASTERNODE" != "" ]; then
#	while [ "$TOKEN" = "" ]; do
	  echo "Copy/Paste in your POSEIDON account's token.  It can be found at https://poseidon.pirl.io/accounts/settings/"
	  echo
	  read -p 'Enter TOKEN:' TOKEN
	  echo
#	done
# else
#	echo "Leaving POSEIDON token as is"
# fi
#echo

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
###or /root/.pirl

##make sure its not running if for reason the service is already there, do clean up incase it was run again  for some reason
echo "Stopping pirl, if it is running."
systemctl stop pirl 2>/dev/null 1>/dev/null
sleep 2
if [ -e $PIRL_PATH ]; then
  echo "Cleaning up previous PIRL installation."
  rm -f $PIRL_PATH 2>/dev/null
fi
#get pirl node
echo "downloading latest PIRL Masternode"
wget -O $PIRL_PATH $DOWNLOAD_LINK_PIRL
downloadresult=$?
chmod 0755 $PIRL_PATH
chmodresult=$?

#double check download and perms
if [ "$downloadresult" != "0" ] || [ "$chmodresult" != "0" ]; then
  echo "error happened downloading the node from:"
  echo $DOWNLOAD_LINK_PIRL
  echo "or trying to chmod it to 0755 at location:"
  echo $PIRL_PATH
  exit 6
fi

echo $SECTION_SEPARATOR
echo

############# grab the marlin-node binary and chmod ############################
###the chain will end up being stored on this users home dir, at /home/username/.pirl/

##make sure its not running if for reason the service is already there, do clean up incase it was run again  for some reason
echo "Stopping marlin, if it is running."
systemctl stop marlin 2>/dev/null 1>/dev/null
sleep 2
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
;EnvironmentFile=$ENV_PATH
Environment=MASTERNODE=$MASTERNODE
Environment=TOKEN=$TOKEN
Type=simple
User=root
Group=root
RestartSec=30s
ExecStart=$PIRL_PATH --ws --wsorigins=* --wsaddr=0.0.0.0 --rpc --rpcaddr=0.0.0.0 --rpccorsdomain="*" --mine --etherbase=0x0000000000000000000000000000000000000001
Restart=always
ExecStartPre=/bin/sleep 5
RemainAfterExit=no
[Install]
WantedBy=multi-user.target
">/lib/systemd/system/pirl.service

#tokens are now in the systemd files
#if [[ -f $ENV_PATH ]]; then
#	echo "token file already present, skipping"
#else
#echo "MASTERNODE=\"$MASTERNODE\"
#TOKEN=\"$TOKEN\"">$ENV_PATH
#echo "Successfully created $ENV_PATH with new tokens"
#fi

###reload in case it was there before, and now could be changed
systemctl daemon-reload

####enable the node
systemctl enable pirl

###start the node
systemctl restart pirl


############ populate files for systemd-marlin service #########
echo "Create pirl-marlin systemd unit file, install, and start."
echo "[Unit]
Description=Pirl Client -- marlin content service
After=network.target pirl.service
Wants=network.target pirl.service
[Service]
;EnvironmentFile=$ENV_PATH
Environment=MASTERNODE=$MASTERNODE
Environment=TOKEN=$TOKEN
Type=simple
User=root
Group=root
RestartSec=30s
ExecStartPre=/bin/sleep 5
ExecStart=$MARLIN_PATH daemon
Restart=always
[Install]
WantedBy=default.target
">/lib/systemd/system/marlin.service
homedir=/root
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
	/usr/bin/marlin init 1>/dev/null
	
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
systemctl enable marlin

###start the node
systemctl restart marlin


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
echo "Check PIRL-node status with: 'systemctl status pirl'"
echo "Check PIRL-marlin status with: 'systemctl status marlin'"
echo "Watch PIRL-node system logs with: 'journalctl -f -u pirl'"
echo "Watch PIRL-marlin system logs with: 'journalctl -f -u marlin'"
if [ "$SET_FIREWALL" = "y" ]; then
   echo "Check firewall status with: 'ufw status'"
fi

exit 0
