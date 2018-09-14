# Common artifacts required for all components
#
# FIXME this doesn't handle removal at all right now.
#
# @summary Management of common artifacts required for all components
#
# @example
#   include arcgis::common
class arcgis::common inherits arcgis::params {

  ##
  # Setup the service user and other system config.
  ##

  contain arcgis::groups::arcgis
  contain arcgis::users::arcgis
  contain arcgis::security::limits
  contain arcgis::config::firewall

  ##
  # Dump out static information so that the next run can
  # better detect the information actually on the system.
  ##

  file { $arcgis::params::static_info_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { $arcgis::params::static_info_path:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => to_json_pretty({
      # Version information
      'current_version'          => $arcgis::params::real_version,
      'supported_versions'       => $arcgis::params::supported_versions,
      # Base Paths
      'path_base'                => $arcgis::params::path_base,
      'path_arcgis'              => $arcgis::params::path_arcgis,
      'path_software'            => $arcgis::params::path_software,
      'path_software_archives'   => $arcgis::params::path_software_archives,
      'path_software_setup'      => $arcgis::params::path_software_setup,
      'path_software_license'    => $arcgis::params::path_software_license,
      'path_software_temp'       => $arcgis::params::path_software_temp,
      # The actual install targets for the products
      'path_server_install'      => $arcgis::params::path_server_install,
      'path_web_adaptor_install' => $arcgis::params::path_web_adaptor_install,
      'path_portal_install'      => $arcgis::params::path_portal_install,
      'path_data_store_install'  => $arcgis::params::path_data_store_install,
      # The actual license file
      'license_file'             => $arcgis::params::license_file,
      # Service user information
      'service_user'             => $arcgis::globals::run_as_user,
      'service_user_home'        => $arcgis::globals::run_as_user_home,
      # Other paths
      'server_tools_dir'         => $arcgis::params::server_tools_dir,
    }),
    require => File[$arcgis::params::static_info_dir],
  }

  ##
  # Setup the rest of our common diectory structure.
  ##

  file { $arcgis::params::path_arcgis:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => Class['arcgis::users::arcgis'],
  }

  file { $arcgis::params::path_software:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0755',
    require => File[$arcgis::params::path_arcgis],
  }

  file { $arcgis::params::path_software_archives:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => File[$arcgis::params::path_software],
  }

  file { $arcgis::params::path_archive_parent:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => File[$arcgis::params::path_software_archives],
  }

  file { $arcgis::params::path_software_setup:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => File[$arcgis::params::path_software],
  }

  file { $arcgis::params::path_unpack_parent:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => File[$arcgis::params::path_software_setup],
  }

  file { $arcgis::params::path_software_license:
    ensure  => directory,
    owner   => 'root',
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0775',
    require => File[$arcgis::params::path_software],
  }

  file { $arcgis::params::path_software_temp:
    ensure  => directory,
    owner   => $arcgis::globals::run_as_user,
    group   => $arcgis::globals::run_as_user_group,
    mode    => '1770',
    require => File[$arcgis::params::path_software],
  }

  archive { $arcgis::params::license_file:
    path          => $arcgis::params::license_file,
    source        => $arcgis::globals::license_file_uri,
    checksum      => $arcgis::globals::license_file_sha1,
    checksum_type => 'sha1',
    extract       => false,
    cleanup       => false,
    user          => $arcgis::globals::run_as_user,
    group         => $arcgis::globals::run_as_user_group,
    temp_dir      => $arcgis::params::path_software_temp,
    require       => [File[$arcgis::params::path_software_license], File[$arcgis::params::path_software_temp]],
  }

  file { $arcgis::params::license_file:
    ensure  => 'present',
    owner   => $arcgis::globals::run_as_user,
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0644',
    require => Archive[$arcgis::params::license_file],
  }

}
