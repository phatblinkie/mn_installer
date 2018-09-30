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
