# mn_installer.sh
This script will install a masternode for PIRL on stock Ubuntu 18.04 64bit.

## This script will do the following
1. Update your box's packages from the Ubuntu repos.
2. Optionally make a user, and home directory, to run the PIRL service.
3. Download the pirl masternode binary and set permissions on it.
4. Setup a systemd service named pirlnode, enable it, and start it.
7. Install the ufw firewall and open needed ports.
8. Optionally update the SSH daemon to run on a non-standard port of your choice.

## To run this script
1. Clone this git repository: `git clone https://github.com/phatblinkie/mn_installer.git`
2. Change into the newly created directory: `cd mn_installer`
3. Run this script via the command: `sudo ./mn_installer.sh`

