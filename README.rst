Kolla-ansible Test
====================

This is my openstack train installation guide for masakari test using
kolla-ansible on Debian buster based machines.

I created 3 virtual machines (1 master and 2 workers) with 
openstack debian 10 buster image.

* deployer/master node

   - hostname: ka-m1
   - CPU: 8 cores
   - RAM; 16 GB
   - Disk: 100 GB
   - IP: 192.168.21.71

* worker nodes

   - hostname: ka-w{1,2}
   - CPU: 8 cores
   - RAM; 16 GB
   - Disk: 100 GB
   - IP: 192.168.21.7{2,3}

Set up dependencies
--------------------

deployer/master node
++++++++++++++++++++++

Stop and disable nscd(Name Service Cache Daemon) service 
since it causes problems with docker.::

    $ sudo systemctl stop unscd.service
    $ sudo systemctl disable unscd.service

Install debian package dependencies::

    $ sudo apt install -y python3-dev libffi-dev gcc libssl-dev 
        python3-selinux python3-setuptools python3-venv gpg nfs-kernel-server

Install python package dependencies.::

    $ python3 -m venv ~/.envs/ka
    $ source ~/.envs/ka/bin/activate
    (ka) $ pip install -U pip wheel
    (ka) $ pip install 'ansible<2.10'

worker nodes
+++++++++++++

Stop and disable nscd(Name Service Cache Daemon) service 
since it causes problems with docker.::

    $ sudo systemctl stop unscd.service
    $ sudo systemctl disable unscd.service

Install debian package dependencies::

    $ sudo apt install -y gpg nfs-common

Install kolla-ansible
------------------------

Install kolla-ansible and its dependencies.::

    (ka) $ pip install kolla-ansible==9.2.0

Create /etc/kolla directory.::

    (ka) $ sudo mkdir -p /etc/kolla
    (ka) $ sudo chown $USER:$USER /etc/kolla

Copy globals.yml and passwords.yml to /etc/kolla directory.::

    (ka) $ cp globals.yml passwords.yml /etc/kolla/

Caveat) If there is another openstack installation using kolla-ansible in
the same network,
Change keepalived_virtual_router_id(default: 51) in /etc/kolla/globals.yml
(e.g. 251).::

   (ka) $ vi /etc/kolla/globals.yml
   ...
   keepalived_virtual_router_id: "251"


Configure
----------

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
Change kolla_internal_vip_address as yours (placeholder: <mgmt_ip>)
It should be non-occupied ip address. (Mine is 192.168.21.70.)

Set up nfs server backend on ka-m1.::

    (ka) $ sudo mkdir -p /kolla_nfs
    (ka) $ echo "/kolla_nfs <your_subnet>/<your_netmask>(rw,sync,no_root_squash)"|sudo tee /etc/exports
    (ka) $ sudo systemctl restart nfs-kernel-server

Change <your_subnet>/<your_netmask> as yours.
Mine was "192.168.21.0/24".

Create /etc/kolla/config/nfs_shares for NFS backend.::

    (ka) $ mkdir -p /etc/kolla/config
    (ka) $ echo "<deployer>:/kolla_nfs" > /etc/kolla/config/nfs_shares

Change hostname "<deployer>" to yours

Deploy
--------

Bootstrap servers with kolla deploy dependencies::

    (ka) $ kolla-ansible -i multinode bootstrap-servers

Do pre-deployment checks for hosts::

    (ka) $ kolla-ansible -i multinode prechecks

Finally proceed to actual OpenStack deployment::

    (ka) $ kolla-ansible -i multinode deploy

It will take a while. 

Deploy specific containers
---------------------------

Deploy masakari containers only.::

   (ka) $ kolla-ansible -i multinode --tags masakari deploy

Destroy
--------

To destroy the deployment, use --yes-i-really-really-mean-it option.::

   (ka) $ kolla-ansible -i multinode destory --yes-i-really-really-mean-it


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

