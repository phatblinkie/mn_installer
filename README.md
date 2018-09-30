# mn_installer.sh
This script will install a premium masternode for PIRL on stock Ubuntu.

## This script will do the following
1. Optionally make a user, and home directory, to run the PIRL service.
2. Download the pirl premium masternode binary and set permissions on it.
3. Download the pirl premium marlin binary and set permissions on it.
3. Setup a systemd service named pirlnode, enable it, and start it.
4. Setup a systemd service named pirlmarlin, enable it, and start it.
