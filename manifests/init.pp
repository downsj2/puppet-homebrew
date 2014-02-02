# == Class: homebrew
#
# Install HomeBrew  for Mac OS/X (http://brew.sh/) as a Puppet package provider
#
# Do not forget to download the command line tools for XCode from Apple and store them on a local repository.
# Caveat: You need an Apple ID to do that!
# 
# For Mavericks:
#  http://adcdownload.apple.com/Developer_Tools/command_line_tools_os_x_mavericks_for_xcode__late_october_2013/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg
# For Mountain Lion:
#  http://adcdownload.apple.com/Developer_Tools/command_line_tools_os_x_mountain_lion_for_xcode__april_2013/xcode462_cltools_10_86938259a.dmg
#
# === Parameters
#
# Document parameters here.
#
# [*xcode_cli_source*]
#   Contains the URL where this module can find the XCode CLI package
#   Default: 'http://puppet/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg'
#
# [*user*]
#   Tells which user will own the Homebrew installation.
#   It is highly encouraged to choose a user different than the default.
#   Default: root
#
# [*group*]
#   Tells which group will own the Homebrew installation.
#   You should add users to this group later on if you want them to be allowed to install brews.
#   Defaults: brew
#
# === Examples
#
#  include homebrew
#
#  To install for a given user:
#
#  class { 'homebrew':
#    user  => gildas,
#    group => brew,
#  }
#
# === Authors
#
# Author Name <gildas.cherruel@inin.com>
#
# === Copyright
#
# Copyright 2014, Gildas CHERRUEL.
#
class homebrew (
  $xcode_cli_source = 'http://puppet/command_line_tools_os_x_mavericks_for_xcode__late_october_2013.dmg',
  $user             = root,
  $group            = brew,
)
{
  $xcode_cli_install = url_parse($xcode_cli_source, 'filename')

  if ($::operatingsystem != 'Darwin')
  {
    err('This Module works on Mac OS/X only!')
    fail("Unsupported OS: ${::operatingsystem}")
  }
  if (versioncmp($::macosx_productversion_major, '10.7') < 0)
  {
    err('This Module works on Mac OS/X Lion or more recent only!')
    fail("Unsupported OS version: ${::macosx_productversion_major}")
  }

  if (! $has_compiler)
  {
    package {$xcode_cli_install:
      ensure   => present,
      provider => pkgdmg,
      source   => $xcode_cli_source,
    }
  }

  $homebrew_directories = [ '/usr/local',
                   '/usr/local/bin',
                   '/usr/local/etc',
                   '/usr/local/include',
                   '/usr/local/lib',
                   '/usr/local/lib/pkgconfig',
                   '/usr/local/Library',
                   '/usr/local/sbin',
                   '/usr/local/share',
                   '/usr/local/var',
                   '/usr/local/var/log',
                   '/usr/local/share/locale',
                   '/usr/local/share/man',
                   '/usr/local/share/man/man1',
                   '/usr/local/share/man/man2',
                   '/usr/local/share/man/man3',
                   '/usr/local/share/man/man4',
                   '/usr/local/share/man/man5',
                   '/usr/local/share/man/man6',
                   '/usr/local/share/man/man7',
                   '/usr/local/share/man/man8',
                   '/usr/local/share/info',
                   '/usr/local/share/doc',
                   '/usr/local/share/aclocal',
                   '/Library/Caches/Homebrew',
                   '/Library/Logs/Homebrew',
                 ]

  group {$group:
    ensure => present,
    name   => $group,
  }

  file {$homebrew_directories:
    ensure  => directory,
    owner   => $homebrew::user,
    group   => $homebrew::group,
    mode    => '0775',
    require => Group[$group],
  }

  if (! defined(File['/etc/profile.d']))
  {
    file {'/etc/profile.d':
      ensure => directory
    }
  }

  file {'/etc/profile.d/homebrew.sh':
    owner   => root,
    group   => wheel,
    mode    => '0775',
    source  => "puppet:///modules/${module_name}/homebrew.sh",
    require => File['/etc/profile.d'],
  }

  exec {'install-homebrew':
    cwd       => '/usr/local',
    command   => "/usr/bin/su ${homebrew::user} -c '/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL https://github.com/mxcl/homebrew/tarball/master | /usr/bin/tar xz -m --strip 1\"'",
    creates   => '/usr/local/bin/brew',
    logoutput => on_failure,
    timeout   => 0,
    require   => File[$directories],
  }
  if (! $has_compiler)
  {
    Package[$xcode_cli_install] -> Exec['install-homebrew']
  }

  file { '/usr/local/bin/brew':
    owner     => $homebrew::user,
    group     => $homebrew::group,
    mode      => '0775',
    require   => Exec['install-homebrew'],
  }
}