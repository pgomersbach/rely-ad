class rely_ad {
# wrapper class

  class {'windows_ad':
    install                => present,
    installmanagementtools => true,
    restart                => true,
    installflag            => true,
    configure              => present,
    configureflag          => true,
    domain                 => 'forest',
    domainname             => 'jre.local',
    netbiosdomainname      => 'jre',
    domainlevel            => '4',
    forestlevel            => '4',
    databasepath           => 'c:\\windows\\ntds',
    logpath                => 'c:\\windows\\ntds',
    sysvolpath             => 'c:\\windows\\sysvol',
    installtype            => 'domain',
    dsrmpassword           => '12_Dwwmjenvgtn',
    installdns             => 'yes',
    localadminpassword     => '12_Dwwmjenvgtn',
  }
}
