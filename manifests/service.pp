define supervisor::service(
  $enable=true, $ensure=present,
  $command, $numprocs=1, $priority=999,
  $autorestart='unexpected',
  $startsecs=1, $retries=3, $exitcodes='0,2',
  $stopsignal='TERM', $stopwait=10, $user='',
  $group='', $redirect_stderr=false,
  $stdout_logfile='',
  $stdout_logfile_maxsize='250MB', $stdout_logfile_keep=10,
  $stderr_logfile='',
  $stderr_logfile_maxsize='250MB', $stderr_logfile_keep=10,
  $environment='', $chdir='', $umask='') {
  include supervisor::params

    $autostart = $ensure ? {
      running => true,
      stopped => false,
      default => false
    }

    file {
      "${supervisor::params::ini_dir}/${name}.${supervisor::params::conf_ext}":
        ensure => $enable ? {
          false => absent,
          default => undef },
        content => $enable ? {
          true => template('supervisor/service.ini.erb'),
          default => undef },
        require => File[$supervisor::params::ini_dir, "/var/log/supervisor/${name}"],
        notify => Exec['supervisor::update'];
      "/var/log/supervisor/${name}":
        ensure => $ensure ? {
          purged => absent,
          default => directory },
        owner => $user ? {
          '' => 'root',
          default => $user },
        group => $group ? {
          '' => 'root',
          default => $group },
        mode => 750,
        recurse => $ensure ? {
          purged => true,
          default => false },
        force => $ensure ? {
          purged => true,
          default => false };
    }

    if ($ensure == 'running' or $ensure == 'stopped') {
      service {
        "supervisor::${name}":
          ensure   => $ensure,
          provider => base,
          restart  => "/usr/bin/supervisorctl restart ${name}",
          start    => "/usr/bin/supervisorctl start ${name}",
          status   => "/usr/bin/supervisorctl status | awk '/^${name}/{print \$2}' | grep '^RUNNING$'",
          stop     => "/usr/bin/supervisorctl stop ${name}",
          require  => [ Package['supervisor'], Service[$supervisor::params::system_service] ];
      }
    }
  }
