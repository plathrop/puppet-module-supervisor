class supervisor::params {
  case $::osfamily {
    'debian': {
      $conf_file      = '/etc/supervisor/supervisord.conf'
      $conf_dir       = '/etc/supervisor'
      $system_service = 'supervisor'
      $package        = 'supervisor'
    }
    'redhat': {
      $conf_file      = '/etc/supervisord.conf'
      $conf_dir       = '/etc/supervisord.d'
      $system_service = 'supervisord'
      $package        = 'supervisor'
    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
