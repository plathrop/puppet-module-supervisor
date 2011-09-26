class supervisor {
  include supervisor::params

  if ! defined(Package[$supervisor::params::package]) { 
    package {"${supervisor::params::package}":
      ensure => installed
    }
  }

  file {
    $supervisor::params::conf_dir:
      ensure  => directory,
      purge   => true,
      require => Package[$supervisor::params::package];
    ['/var/log/supervisor',
     '/var/run/supervisor']:
      ensure  => directory,
      purge   => true,
      backup  => false,
      require => Package[$supervisor::params::package];
    $supervisor::params::conf_file:
      content => template('supervisor/supervisord.conf.erb'),
      require => Package[$supervisor::params::package],
      notify  => Service[$supervisor::params::system_service];
    '/etc/logrotate.d/supervisor':
      source => 'puppet:///modules/supervisor/logrotate',
      require => Package[$supervisor::params::package];
  }

  service {
    $supervisor::params::system_service:
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package[$supervisor::params::package];
  }

  exec {
    'supervisor::update':
      command     => '/usr/bin/supervisorctl update',
      logoutput   => on_failure,
      refreshonly => true,
      require     => Service[$supervisor::params::system_service];
  }
}
