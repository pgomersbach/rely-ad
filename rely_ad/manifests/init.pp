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
  # validata parameters
  include stdlib
  validate_string($myhostname)
  validate_string($domain)
  validate_string($domainname)
  validate_string($netbiosdomainname)
  validate_integer($domainlevel)
  validate_integer($forestlevel)
  validate_string($installtype)
  validate_string($dsrmpassword)
  validate_string($localadminpassword)

  # set update policy
  class { 'windows_autoupdate':
    noAutoUpdate => '1',
    aUOptions    => '2',
  }

  # disable EC2Config set hostname 
  file { 'ec2config':
    path               => 'C:\Program Files\Amazon\Ec2ConfigService\Settings\config.xml',
    source             => 'puppet:///modules/rely_ad/ec2config.xml',
    source_permissions => ignore,
  }

  #change hostname
  if $myhostname != $::hostname {
    exec {  'change_hostname':
      command => "wmic ComputerSystem where Name=\"${::hostname}\" call Rename Name=\"${myhostname}\"",
      path    => $::path,
      before  => Class ['windows_ad'],
      require => File ['ec2config'],
      notify  => Reboot ['after'],
    }
  }

  # disable ipv6
  class {'windows_disable_ipv6':
    ipv6_disable => true,
    ipv6_reboot  => false,
  }

  # register nic connection in dns and use this connect suffix in dns registration
  exec {  'enable_dnsregistration':
    command  => '(Get-WmiObject Win32_NetworkAdapter -Filter "NetEnabled=True").GetRelated(\'Win32_NetworkAdapterConfiguration\').SetDynamicDNSRegistration($true,$true)',
    path     => $::path,
    onlyif   => 'if ((Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq "True"}).FullDNSRegistrationEnabled) { exit 1 }',
    provider => powershell,
  }

# set search domain

  reboot { 'before':
    when            => pending,
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
    require                => Reboot['before'],
  }

  # create ptr zone
  $masklen = netmask_to_masklen($::netmask)
  exec { 'create_ptr_zone':
    command  => "Add-DnsServerPrimaryZone -NetworkID \"$::network_ethernet/$masklen\" -ReplicationScope \"domain\"",
    path     => $::path,
    onlyif   => "Add-DnsServerPrimaryZone -NetworkID \"$::network_ethernet/$masklen\" -ReplicationScope \"domain\"",
    provider => powershell,
    require  => Class[ 'windows_ad' ],
  }

  # create ptr record
#  notify { "Add-DnsServerResourceRecord -Name \"33.167\" -Ptr -ZoneName \"0.10.in-addr.arpa\" -AllowUpdateAny -PtrDomainName \"$::fqdn\"": }

  # enable ad recycle bin
  $array_var = split($domainname, '[.]')
  $domfirst = $array_var[0]
  $domsec = $array_var[1]
  exec {  'enable_ad_ recyclebin':
    command  => "Enable-ADOptionalFeature -Identity \'CN=Recycle Bin Feature,CN=Optional Features,CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration,DC=$domfirst,DC=$domsec\' -Scope ForestOrConfigurationSet -Target \'$domainname\' -Confirm:\$false",
    path     => $::path,
    unless   => 'Get-ADOptionalFeature -filter * | findstr Recycle',
    provider => powershell,
    require  => Class[ 'windows_ad' ],
  }

  reboot { 'after': }
}
