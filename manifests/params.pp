class supervisor::params {
  case $operatingsystem {
    'ubuntu','debian': {
      $conf_file = '/etc/supervisor/supervisord.conf'
      $conf_dir = '/etc/supervisor'
      $ini_dir = "${conf_dir}/conf.d"
      $system_service = 'supervisor'
      $package = 'supervisor'
    }
    'centos','fedora','redhat': {
      $conf_file = '/etc/supervisord.conf'
      $conf_dir = '/etc/supervisor.d'
      $ini_dir = $conf_dir
      $system_service = 'supervisord'
      $package = 'supervisor'
    }
  }
}
