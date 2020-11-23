Set up Masakari 
=================

This is a guide to set up masakari service.

Create a segment.::

   (ka) $ openstack segment create okidoki auto COMPUTE

Create a host in a segment.::

   (ka) $ openstack segment host create <compute_hostname> COMPUTE SSH okidoki

