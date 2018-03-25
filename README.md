# mn_installer.sh
script to install masternode for pirl on stock ubuntu 16 64bit
This should be run as root and will do the following
1. update your boxes packages from the ubuntu repos
2. make a pirl username to run the service as, and a home directory
3. download the pirl masternode binary and set permissions on it
4. setup a systemd service named pirlnode, enable it, and start it
5. setup the template for the needed environment variables for it to report properly to poseidon
