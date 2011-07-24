class supervisor {
  package {
    supervisor:
      ensure => installed;
  }

  $supervisor_conf_file = $operatingsystem ? {
    /(Ubuntu|Debian)/ => '/etc/supervisor/supervisord.conf',
    /(Fedora|CentOS)/ => '/etc/supervisord.conf',
  }

  $supervisor_conf_dir = $operatingsystem ? {
    /(Ubuntu|Debian)/ => '/etc/supervisor',
    /(Fedora|CentOS)/ => '/etc/supervisord.d',
  }

  $supervisor_system_service = $operatingsystem ? {
    /(Ubuntu|Debian)/ => 'supervisor',
    /(Fedora|CentOS)/ => 'supervisord',
  }

  file {
    $supervisor_conf_dir:
      ensure  => directory,
      purge   => true,
      require => Package['supervisor'];
    ['/var/log/supervisor',
     '/var/run/supervisor']:
      ensure  => directory,
      purge   => true,
      backup  => false,
      require => Package['supervisor'];
    $supervisor_conf_file:
      content => template('supervisor/supervisord.conf.erb'),
      require => Package['supervisor'];
    '/etc/logrotate.d/supervisor':
      source => 'puppet:///modules/supervisor/logrotate',
      require => Package['supervisor'];
  }

  service {
    $supervisor_system_service:
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
      require     => Service[$supervisor_system_service];
  }
}
