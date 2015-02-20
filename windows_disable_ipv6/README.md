# puppet-windows_disable_ipv6

Puppet module to disable ipv6 on Windows platforms

===

# Compatability

This module has been tested to work on the following systems with Puppet v3 and Ruby versions 1.8.7, 1.9.3 and 2.0.0.

 * Windows Server 2008 R2
 * Windows Server 2012 R2

===

# Parameters

ipv6_disable
-----------
Disable ipv6.

- *Default*: false

ipv6_reboot
---------------------------
Reboot the machine after the ipv6_disable setting has been changed in order for the setting to take effect.

- *Default*: false

===

## Sample usage:
Disable ipv6 through Hiera.

<pre>
windows_disable_ipv6::ipv6_disable: true
windows_disable_ipv6::ipv6_reboot: true
</pre>
