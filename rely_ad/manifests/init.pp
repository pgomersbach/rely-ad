class rely_ad (
  $myhostname='testserver',
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
# disable ipv6
  # set hostname
  if $myhostname != $::hostname {
    notify { 'hostname change required': }
  }

  # install ad
  class {'windows_ad':
    install                => present,
    installmanagementtools => true,
    restart                => true,
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
  }
# activate ad recyclebin
# ptr enable
}
