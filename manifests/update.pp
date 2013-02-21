class supervisor::update {
  exec { 'supervisor::update':
    command     => '/usr/local/bin/supervisorctl update',
    logoutput   => on_failure,
    refreshonly => true,
    require     => Service[$supervisor::params::system_service],
  }
}
