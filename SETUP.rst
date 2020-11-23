Setup
======

This is a guide to set up openstack services using kolla-ansible.

I denoted (Debian10) and (CentOS7) to distinguish which OS it is.
If there is not denotation, it's common to both OS.

Pre-requisite
--------------

Kolla-ansible should be installed.

Refer to INSTALL.rst.

Configure
----------

*(CentOS7)*
Create ansible.cfg.::

    (ka) $ cat << EOF > ansible.cfg
    [defaults]
    nocolor = True
    callback_whitelist = profile_tasks
    host_key_checking=False
    pipelining=True
    forks=100
    deprecation_warnings = False
    EOF

*(Debian10)*
Create ansible.cfg.::

    (ka) $ cat << EOF > ansible.cfg
    [defaults]
    nocolor = True
    callback_whitelist = profile_tasks
    host_key_checking=False
    pipelining=True
    forks=100
    deprecation_warnings = False
    interpreter_python=/usr/bin/python3
    EOF

Copy masakari directory to virtualenv.::

    (ka) $ cp -a masakari ~/.envs/ka/share/kolla-ansible/ansible/roles/

Copy remove role to virtualenv.::

    (ka) $ cp -a kolla-ansible/roles/remove \
            ~/.envs/ka/share/kolla-ansible/ansible/roles/
    (ka) $ cp kolla-ansible/remove.yml ~/.envs/ka/share/kolla-ansible/ansible/

Copy kolla-ansible script to virtualenv.::

   (ka) $ mv ~/.envs/ka/bin/kolla-ansible ~/.envs/ka/bin/kolla-ansible.bak
   (ka) $ cp kolla-ansible/bin/kolla-ansible ~/.envs/ka/bin/

Copy remove-container script to virtualenv.::

   (ka) $ cp kolla-ansible/tools/remove-containers \
            ~/.envs/ka/share/kolla-ansible/tools/

Copy multinode.sample to multinode and edit multinode file to set up inventory.

* Change hostnames as yours.
* Change <userid> to your uid.
* Change <user_password> to your user's password.

Check whether the configuration of inventory is correct or not, run:

    (ka) $ ansible -i multinode -m ping all
    [WARNING]: Invalid characters were found in group names but not replaced,
    use -vvvv to see details
    localhost | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    ka-m1 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    ka-w1 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }
    ka-w2 | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }

Create random passwords.::

    (ka) $ kolla-genpwd

Edit /etc/kolla/globals.yml.
Change kolla_internal_vip_address as yours (placeholder: <mgmt_ip>).
It should be non-occupied ip address. (Mine is 192.168.21.90.)

Set up nfs server backend on ka-m1.::

    (ka) $ sudo mkdir -p /kolla_nfs
    (ka) $ echo "/kolla_nfs <your_subnet>/<your_netmask>(rw,sync,no_root_squash)"|sudo tee /etc/exports
    (ka) $ sudo systemctl enable nfs-server
    (ka) $ sudo systemctl start nfs-server

Change <your_subnet>/<your_netmask> as yours.
Mine is "192.168.21.0/24".

Create /etc/kolla/config/nfs_shares for NFS backend.::

    (ka) $ mkdir -p /etc/kolla/config
    (ka) $ echo "<deployer>:/kolla_nfs" > /etc/kolla/config/nfs_shares

Change hostname "<deployer>" to yours.

Deploy
--------

Bootstrap servers with kolla deploy dependencies::
    (ka) $ kolla-ansible -i multinode bootstrap-servers

Do pre-deployment checks for hosts::

    (ka) $ kolla-ansible -i multinode prechecks

Finally proceed to actual OpenStack deployment::

    (ka) $ kolla-ansible -i multinode deploy

It will take a while.

Deploy specific service
---------------------------

Deploy masakari service only.::

   (ka) $ kolla-ansible -i multinode --tags masakari deploy

Remove specific service
-------------------------

Remove masakari service only.::

   (ka) $ kolla-ansible -i multinode \
            -e remove_service='masakari' remove --include-images

It stop and delete masakari containers and volumes and
remove masakari images (--include-images option).

Destroy
--------

To destroy the deployment, use --yes-i-really-really-mean-it option.::

   (ka) $ kolla-ansible -i multinode destroy \
            --yes-i-really-really-mean-it --include-images

It destroys all containers and volumes and 
remove all kolla images (--include-images option).

Using OpenStack
------------------

Install the OpenStack CLI client for your openstack version
I installed openstack train so I'll install openstack train client.::

    (ka) $ pip install python-openstackclient==4.0.1 \
                        python-masakariclient==5.3.0

OpenStack requires an openrc file where credentials for admin user are set.
To generate this file::

    (ka) $ kolla-ansible post-deploy
    (ka) $ sudo chown $USER:$USER /etc/kolla/admin-openrc.sh
    (ka) $ source /etc/kolla/admin-openrc.sh

Put virtualenv and admin-openrc sourcing to .bashrc so that
you do not need to source them whenever you login.::

    (ka) $ cat <<EOF > $HOME/.bashrc
    # kolla virtualenv and adminrc
    source $HOME/.envs/ka/bin/activate
    source /etc/kolla/admin-openrc.sh
    EOF

