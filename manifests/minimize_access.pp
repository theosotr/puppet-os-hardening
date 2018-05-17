# === Copyright
#
# Copyright 2014, Deutsche Telekom AG
# Licensed under the Apache License, Version 2.0 (the "License");
# http://www.apache.org/licenses/LICENSE-2.0
#

# == Class: os_hardening::minimize_access
#
# Configures profile.conf.
#
class os_hardening::minimize_access (
  Boolean $allow_change_user   = false,
  Array   $always_ignore_users =
    ['root','sync','shutdown','halt'],
  Array   $ignore_users        = [],
  String  $shadowgroup         = 'root',
  String  $shadowmode          = '0600',
  Integer $recurselimit        = 5,
) {

  case $::operatingsystem {
    redhat, fedora: {
      $nologin_path = '/sbin/nologin'
    }
    debian, ubuntu: {
      $nologin_path = '/usr/sbin/nologin'
    }
    default: {
      $nologin_path = '/sbin/nologin'
    }
  }
  # from which folders to remove public access
  $folders = [
    '/usr/local/sbin',
    '/usr/sbin',
    '/usr/bin',
    '/sbin',
    '/bin',
  ]

  # remove write permissions from path folders ($PATH) for all regular users
  # this prevents changing any system-wide command from normal users
  file { $folders:
    ensure       => directory,
    links        => follow,
    mode         => 'go-w',
    recurse      => true,
    recurselimit => $recurselimit,
  }

  # shadow must only be accessible to user root
  file { '/etc/shadow':
    ensure => file,
    owner  => 'root',
    group  => $shadowgroup,
    mode   => $shadowmode,
  }

  # su must only be accessible to user and group root
  if $allow_change_user == false {
    file { '/bin/su':
      ensure => file,
      links  => follow,
      owner  => 'root',
      group  => 'root',
      mode   => '0750',
    }
  } else {
    file { '/bin/su':
      ensure => file,
      links  => follow,
      owner  => 'root',
      group  => 'root',
      mode   => '4755',
    }
  }

  # retrieve system users through custom fact
  $system_users = split($::retrieve_system_users, ',')

  # build array of usernames we need to verify/change
  $ignore_users_arr = union($always_ignore_users, $ignore_users)

  # build a target array with usernames to verify/change
  $target_system_users = difference($system_users, $ignore_users_arr)

  # ensure accounts are locked (no password) and use nologin shell
  user { $target_system_users:
    ensure   => present,
    shell    => $nologin_path,
    password => '*',
  }

}

