Puppet module for configuring the 'supervisor' daemon control
utility. Currently only tested on Debian.

Install into your <puppet module_path>/supervisor

Example usage::

  supervisor::service {
    "scribe":
      enable => true,
      ensure => running,
      command => "/usr/bin/scribed -c /etc/scribe/scribe.conf",
      environment => "HADOOP_HOME=/usr/lib/hadoop,LD_LIBRARY_PATH=/usr/lib/jvm/java-6-sun/jre/lib/amd64/server",
      user => "scribe",
      group => "scribe",
      require => [ Package["scribe"], User["scribe"] ];
  }
