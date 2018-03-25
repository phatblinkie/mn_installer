#define vars for node
#these come from poseidon.pirl.io  
#-------Change the values below to influence how the script sets up your node and firewall------#

#this one is on your masternode page, and is unique for each masternode you have
#replace with your own values from poseidon
MASTERNODE="----"

#this one is on your account page, and is the only one for your account
TOKEN=""

#change ssh port to (recommended range is 1025-65535) 
#if you change this from the default value of port 22, 
# then the script will update your box to run ssh on the new port, and configure that value in the firewall
SSHD_PORT="22"

#your home ip address for the firewall to only allow your ip into ssh
#if you do not have an ip at home that stays the same, leave the below value
#if left to be a.b.c.d then the script will ignore it
YOURIP="a.b.c.d"

#username you want the service to run as, if you want it to run as root, leave root
#if you want it to run as pirl put in pirl. no spaces allowed, and all lower case please.
#this user will not be used as a login user, so no password will be set.
RUNAS_USER="root"



######################################################################
########################## No editing below this #####################
######################################################################
#first, check the tokens
if [ "$MASTERNODE" = "----" ]
  then
  echo Please set your master node token from poseidon and run again
  exit 1
fi

if [ "$TOKEN" = "" ]
  then
  echo Please set your account token from poseidon and run again
  exit 2
fi

#sanity check username pattern
pattern=" |'|[A-Z]"
if [ $NAME =~ $pattern ]
  then
  echo username rules breached. no spaces, or caps allowed.
  exit 3
fi

#check if username already exists, if so, does it have a valid home dir for chain storage?
getent passwd $NAME > /dev/null 
if [ $? -eq 0 ]; then
    echo "User $NAME exists"
    homedir=$( getent passwd "$NAME" | cut -d: -f6 )
    if [ ! -d $homedir ]
      then
      echo "existing user have no home dir, or its not available. exiting.
      echo 4
    fi
fi

#one last check for ip structure. fail if its out of bounds

exit 0
------pending  more updates, do not use yet

#update packages
apt-get update
apt-get dist-upgrade -y
apt-get install ufw -y
#firewall rules
systemctl enable ufw
ufw allow from $YOURIP
ufw allow 30303/tcp
ufw allow 30303/udp
ufw default allow outgoing
ufw default deny incoming
ufw enable
ufw status
#get pirl node
wget http://release.pirl.io/downloads/masternode/linux/pirl
chmod 0755 pirl

######populate files#########
echo -e "[Unit]
Description=Pirl Master Node

[Service]
; location of the file with the exported variables
EnvironmentFile=/etc/pirlnode-env

Type=simple
;created with useradd pirl
User=root
Group=root

ExecStart=/root/pirl
Restart=always

[Install]
WantedBy=default.target
">/etc/systemd/system/pirlnode.service

echo -e "MASTERNODE=\"$MASTERNODE\"
TOKEN=\"$TOKEN\"
">/etc/pirlnode-env


####enable the node
systemctl enable pirlnode

###start the node
systemctl start pirlnode

echo -e "\n\n can monitor with journalctl --unit=pirlnode -f \n\n"
sleep 3


##add the php stuff here
