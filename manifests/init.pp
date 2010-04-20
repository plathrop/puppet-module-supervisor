class supervisor {
  package {
    "supervisor":
      ensure => installed;
  }

  file {
    "/etc/supervisor":
      purge => true,
      ensure => directory,
      require => Package["supervisor"];
    ["/var/log/supervisor",
     "/var/run/supervisor"]:
       purge => true,
       backup => false,
       ensure => directory,
       require => Package["supervisor"];
     "/etc/supervisor/supervisord.conf":
       source => "puppet:///supervisor/supervisord.conf",
       require => Package["supervisor"];
     "/etc/logrotate.d/supervisor":
       source => "puppet:///supervisor/logrotate",
       require => Package["supervisor"];
  }

  service {
    "supervisor":
      enable => true,
      ensure => running,
      hasrestart => false,
      require => Package["supervisor"],
      pattern => "/usr/bin/supervisord";
  }

  exec {
    "supervisor::update":
      command => "/usr/bin/supervisorctl update",
      logoutput => on_failure,
      refreshonly => true,
      require => Service["supervisor"];
  }
}
