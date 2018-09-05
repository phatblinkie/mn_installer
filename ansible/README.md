# PIRL Masternode Installer
This installer uses Ansible to configure your system to be a PIRL masternode.

# Steps
*  Install Ansible on your machine.
   * Debian/Ubuntu: #`apt install ansible`
   * RedHat/CentOS: #`yum install ansible`
*  Modify the file *hosts.yml* and fix the *MASTERNODE* and *TOKEN* variables to match your setup.
*  Optional:  In the hosts.yml file change the RUNAS_USER variable to be which user you'd like the masternode to run as.
*  Run the command: `ansible-playbook -K mn_installer.yml` to start the installation.  This might take some time so be patient.

# Troubleshooting
If you messed up your MASTERNODE and/or TOKEN variables you can either change them as describe above and rerun the installer
or you can edit the /etc/pirlnode-env file and fix them there.  If you edit that file be sure to restart the pirlnode service
with: `sudo systemd restart pirlnode.service`.
