# mn_installer.sh
This script will install a premium masternode v5-beta for PIRL on stock Ubuntu.

## This script will do the following
1. Ask user to enter his MN token and Poseidon token.
2. If a user already had Premium node installation and only wants to upgrade binaries tokens will not be changed.
3. Optionally make a user, and home directory, to run the PIRL service.
4. Download pirl premium masternode binary and set permissions on it.
5. Download pirl premium marlin binary and set permissions on it.
6. Setup a systemd service named pirlnode, enable it, and start it.
7. Check out if pirl marlin was initialized before. If not will initialize it.
8. Setup a systemd service named pirlmarlin, enable it, and start it.
9. If user wants to change SSH port, install firewall and upgrade system, runs firewall.sh module.

## firewall.sh module will do the following
1. Upgrades system if user allows.
2. Install the ufw firewall and open needed ports.
3. Optionally update the SSH daemon to run on a non-standard port of your choice.

## To run this script
1. Clone this git repository: `git clone https://github.com/phatblinkie/pirl_mn_installer.git`
2. Change into the newly created directory: `cd pirl_mn_installer`
3. Run this script via the command: `sudo ./pirl_mn_installer.sh`

