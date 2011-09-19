class supervisor {
  if ! defined(Package['supervisor']) { package {'supervisor': ensure => installed}}


  $conf_file = $operatingsystem ? {
    /(Ubuntu|Debian)/ => '/etc/supervisor/supervisord.conf',
    /(Fedora|CentOS)/ => '/etc/supervisord.conf',
  }

  $conf_dir = $operatingsystem ? {
    /(Ubuntu|Debian)/ => '/etc/supervisor',
    /(Fedora|CentOS)/ => '/etc/supervisord.d',
  }

  $system_service = $operatingsystem ? {
    /(Ubuntu|Debian)/ => 'supervisor',
    /(Fedora|CentOS)/ => 'supervisord',
  }

  file {
    $conf_dir:
      ensure  => directory,
      purge   => true,
      require => Package['supervisor'];
    ['/var/log/supervisor',
     '/var/run/supervisor']:
      ensure  => directory,
      purge   => true,
      backup  => false,
      require => Package['supervisor'];
    $conf_file:
      content => template('supervisor/supervisord.conf.erb'),
      require => Package['supervisor'],
      notify  => Service[$system_service];
    '/etc/logrotate.d/supervisor':
      source => 'puppet:///modules/supervisor/logrotate',
      require => Package['supervisor'];
  }

  service {
    $system_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package['supervisor'];
  }

  exec {
    'supervisor::update':
      command     => '/usr/bin/supervisorctl update',
      logoutput   => on_failure,
      refreshonly => true,
      require     => Service[$system_service];
  }
}
