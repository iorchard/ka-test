Build
======

This is a guide to build masakari images from customized masakari sources.

Get masakari-monitors source.::

   (ka) $ git clone -b stable/train-okidoki \
            https://github.com/iorchard/masakari-monitors.git

Get masakari source.::

   (ka) $ git clone -b stable/train \
            https://github.com/iorchard/masakari.git

Get kolla source.::

   (ka) $ git clone -b stable/train \
            https://github.com/openstack/kolla.git

Install kolla.::

   (ka) $ pip install kolla==9.2.0 tox

Build masakari images.::

   (ka) $ python tools/build.py --config-file kolla-build.conf masakari-



