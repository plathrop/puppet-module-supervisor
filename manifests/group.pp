# Actions:
#   Set up a group
#
# Sample Usage:
#  supervisor::group { 'my_group':
#    programs,
#    priority => undef
#  }
#
define supervisor::group (
  $programs,
  $ensure    = 'present',
  $priority  = undef
) {
  case $ensure {
    'absent': {
    }
    'present': {
    }
    default: {
      fail("ensure must be 'present', 'absent', not ${ensure}")
    }
  }

  $conf_file = "${supervisor::conf_dir}/group-${name}${supervisor::conf_ext}"

  file { $conf_file:
    ensure  => $ensure,
    content => template('supervisor/group.ini.erb')
  }

  File[$conf_file] ~> Class['supervisor::update'] #-> Service["supervisor::${name}"]
}
