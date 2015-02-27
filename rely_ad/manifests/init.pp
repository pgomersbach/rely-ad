class rely_ad (
  $myhostname='mytestserver',
  $domain='forest',
  $domainname='jre.local',
  $netbiosdomainname='jre',
  $domainlevel='6',
  $forestlevel='6',
  $installtype='domain', # replica for second
  $dsrmpassword='12_Changeme',
  $localadminpassword='12_Changeme',
){
# wrapper class

# set search domain
# register nic connection in dns
# use this connects sufix in dns registration

  exec {  'enable_dnsregistration':
    command   => '$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration | where{$_.IPEnabled -eq "TRUE"} Foreach($NIC in $NICs) { $NIC.SetDynamicDNSRegistration("TRUE")',
    path      => $::path,
    provider  => powershell,
  }

# disable ipv6
  class {'windows_disable_ipv6':
    ipv6_disable => true,
    ipv6_reboot  => false,
    notify       => Reboot['after_run'],
  }

  # set hostname
#  dsc_xcomputer {'change_hostname':
#    dsc_ensure       => 'present',
#    dsc_name         => "$myhostname",
#  }

  dsc_windowsfeature {'IIS':
    dsc_ensure => 'present',
    dsc_name   => 'Web-Server',
  }
#  if $myhostname != $::hostname {
#    notify { "hostname change required, from $::hostname to $myhostname": }
#    exec {  'change_hostname':
#      command   => "wmic computersystem where name=\"$::hostname\" call rename name=\"$myhostname\"",
#      path      => $::path,
#      notify    => Reboot['after_run'],
#    }
#  }

  # install ad
  class {'windows_ad':
    install                => present,
    installmanagementtools => true,
    restart                => false,
    installflag            => true,
    configure              => present,
    configureflag          => true,
    globalcatalog          => 'yes',
    domain                 => $domain,
    domainname             => $domainname,
    netbiosdomainname      => $netbiosdomainname,
    domainlevel            => $domainlevel,
    forestlevel            => $forestlevel,
    databasepath           => 'c:\\windows\\ntds',
    logpath                => 'c:\\windows\\ntds',
    sysvolpath             => 'c:\\windows\\sysvol',
    installtype            => $installtype,
    dsrmpassword           => $dsrmpassword,
    installdns             => 'yes',
    localadminpassword     => $localadminpassword,
    notify                 => Reboot['after_run'],
  }

  reboot { 'after_run':
    apply  => finished,
  }
# activate ad recyclebin
# ptr enable
}
