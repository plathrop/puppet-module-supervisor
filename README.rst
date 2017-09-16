=========================
Puppet Module: Supervisor
=========================
----------
Deprecated
----------

**Please Note: This code is here for historical purposes only.** I
 have not used this module in production for many years. Although it
 is still in use by others, and occasional contributions come in, you
 use it at your own risk. I merge in contributions if they look
 appropriate, but do not provide support or maintenance.

Module Information
==================

Puppet module for configuring the 'supervisor' daemon control
utility. Currently tested on Debian, Ubuntu, and Fedora.

Install into `<module_path>/supervisor`

Example usage:

.. code-block:: puppet

  include supervisor

  supervisor::service {
    'scribe':
      ensure      => present,
      command     => '/usr/bin/scribed -c /etc/scribe/scribe.conf',
      environment => 'HADOOP_HOME=/usr/lib/hadoop,LD_LIBRARY_PATH=/usr/lib/jvm/java-6-sun/jre/lib/amd64/server',
      user        => 'scribe',
      group       => 'scribe',
      require     => [ Package['scribe'], User['scribe'] ];
  }

To use default debian paths:

.. code-block:: puppet

  class { 'supervisor':
    conf_dir => '/etc/supervisor/conf.d',
    conf_ext => '.conf',
  }

Running tests:

.. code-block:: sh

  $ bundle install --path=.gems
  $ bundle exec rake spec
