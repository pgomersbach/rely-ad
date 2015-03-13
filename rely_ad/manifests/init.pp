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
# ptr enable
  $masklen = netmask_to_masklen($::netmask)
  notify { $masklen: }


  # activate ad recyclebin (check forest level => 4
  if  $forestlevel >= '4' {
    $array_var = split($domainname, '[.]')
    $domfirst = $array_var[0]
    $domsec = $array_var[1]
    notify { "forestlevel $forestlevel detected, enable recycle bin for $domfirst $domsec": }
    exec {  'enable_ad_ recyclebin':
      command  => "Enable-ADOptionalFeature -Identity \'CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=$domfirst,DC=$domsec\' -Scope ForestOrConfigurationSet -Target \'$domainname\' -Confirm:\$false",
      path     => $::path,
      unless   => 'Get-ADOptionalFeature -filter * | findstr Recycle',
      provider => powershell,
    }
  }

  # register nic connection in dns and use this connect suffix in dns registration
  exec {  'enable_dnsregistration':
    command  => '(Get-WmiObject Win32_NetworkAdapter -Filter "NetEnabled=True").GetRelated(\'Win32_NetworkAdapterConfiguration\').SetDynamicDNSRegistration($true,$true)',
    path     => $::path,
    onlyif   => 'if ((Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq "True"}).FullDNSRegistrationEnabled) { exit 1 }',
    provider => powershell,
  }

  # disable ipv6
  class {'windows_disable_ipv6':
    ipv6_disable => true,
    ipv6_reboot  => false,
    notify       => Reboot['after_run'],
  }

  # change hostname
  if $myhostname != $::hostname {
    notify { "hostname change required, from ${::hostname} to ${myhostname}": }
    exec {  'change_hostname':
      command => "wmic computersystem where name=\"${::hostname}\" call rename name=\"${myhostname}\"",
      path    => $::path,
      notify  => Reboot['after_run'],
    }
  }

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
}
