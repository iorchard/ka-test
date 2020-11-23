Install
========

This is a guide to install kolla-ansible.

I denoted (Debian10) and (CentOS7) to distinguish which OS it is.
If there is not denotation, it's common to both OS.

Create 6 virtual machines (3 master and 3 workers).

* deployer node

   - hostname: ka-m1
   - CPU: 8 cores
   - RAM; 8 GB
   - Disk: 100 GB
   - IP: 192.168.21.91

* master nodes

   - hostname: ka-m{1,2,3}
   - CPU: 8 cores
   - RAM; 8 GB
   - Disk: 100 GB
   - IP: 192.168.21.9{1,2,3}

* worker nodes

   - hostname: ka-w{1,2,3}
   - CPU: 8 cores
   - RAM; 8 GB
   - Disk: 100 GB
   - IP: 192.168.21.9{4,5,6}

Set up dependencies
--------------------

deployer
+++++++++

*(CentOS7)*
Remove python-requests since it conflicts with kolla-ansible.::

   $ sudo yum remove -y python-requests

*(Debian10)*
Stop and disable nscd(Name Service Cache Daemon) service
since it causes problems with docker.::

    $ sudo systemctl stop unscd.service
    $ sudo systemctl disable unscd.service

*(CentOS7)*
Install rpm packages.::

    $ sudo yum install -y python3-devel nfs-utils sshpass libselinux-python

*(Debian10)*
Install deb packages.::

    $ sudo apt install -y python3-dev libffi-dev gcc libssl-dev 
        python3-selinux python3-setuptools python3-venv gpg nfs-kernel-server


Install python package dependencies.::

    $ python3 -m venv ~/.envs/ka
    $ source ~/.envs/ka/bin/activate
    (ka) $ pip install -U pip wheel
    (ka) $ pip install 'ansible<2.10'

master/worker nodes
+++++++++++++++++++++

*(CentOS7)*
Remove python-requests since it conflicts with kolla-ansible.::

   $ sudo yum remove -y python-requests

*(Debian10)*
Stop and disable nscd(Name Service Cache Daemon) service
since it causes problems with docker.::

    $ sudo systemctl stop unscd.service
    $ sudo systemctl disable unscd.service

*(CentOS7)*
Install rpm packages.::

    $ sudo yum install -y python3 nfs-utils sshpass libselinux-python

*(Debian10)*
Install deb packages::

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

