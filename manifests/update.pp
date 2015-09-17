class supervisor::update {
  exec { 'supervisor::update':
    command     => '/usr/bin/supervisorctl update',
    logoutput   => on_failure,
    onlyif      => "/usr/bin/env test -S ${supervisor::unix_server_file}",
    refreshonly => true,
    require     => Service[$supervisor::params::system_service],
  }
}
