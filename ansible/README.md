# PIRL Masternode Installer
This installer uses Ansible to configure your system to be a PIRL masternode.

# Steps
*  Install Ansible on your machine.
   * Debian/Ubuntu: #`apt install ansible`
   * RedHat/CentOS: #`yum install ansible`
*  Copy the env.cfg-sample to env.cfg.  `cp env.cfg-sample env.cfg`
*  Modify the file *env.cfg* file and fix the *MASTERNODE* and *TOKEN* variables to match your setup.  `nano env.cfg`
*  Optional:  In the env.cfg file change the RUNAS_USER variable to be which user you'd like the masternode to run as.
*  Run the command: `ansible-playbook -K mn_installer.yml` to start the installation.  This might take some time so be patient.

# Troubleshooting
If you messed up your MASTERNODE and/or TOKEN variables you can either change them as describe above and rerun the installer
or you can edit the /etc/pirlnode-env file and fix them there.  If you edit that file be sure to restart the pirlnode service
with: `sudo systemd restart pirlnode.service`.
