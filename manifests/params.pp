class supervisor::params {
    $conf_file      = '/etc/supervisord.conf'
    $conf_dir       = '/etc/supervisord.d'
    $system_service = 'supervisord'
    $package        = 'supervisor'
    $init_file      = '/etc/init/supervisord.conf'
}
