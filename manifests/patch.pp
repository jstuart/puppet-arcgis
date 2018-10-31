# Define a patch that should be applied once installation is complete
#
# @summary Define a patch that should be applied once installation is complete
#
# @example
#   arcgis::patch { 'name': }
define arcgis::patch(
  String $archive_file,
  String $archive_sha1,
  Enum['server'] $type                                              = 'server',
  # The optional QFE ID which will default to $name
  Optional[String] $qfe_id                                          = undef,
  # The optional URI to completely override the package location
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri = undef,
) {
  include arcgis::params

  if $qfe_id and !empty($qfe_id) {
    $_qfe_id = $qfe_id
  } else {
    $_qfe_id = $name
  }

  if empty($archive_file) or empty($archive_sha1) {
    fail('Patch $archive_file and $archive_sha1 are required.')
  }

  $path = $arcgis::params::path_archive_parent
  $archive_package_file = "${path}/${archive_file}"
  $extract_path = "${arcgis::params::path_unpack_parent}/${_qfe_id}"
  $apply_script = "${extract_path}/applypatch"
  $run_indicator = "${extract_path}/.puppet_executed"

  case $type {
    'server': {
      include arcgis::server
      $patch_type_flag = '-server'
      $patch_install_require = [Class['arcgis::server'], Archive[$archive_package_file]]
    }
    default: {
      $patch_type_flag = ''
      $patch_install_require = [Archive[$archive_package_file]]
    }
  }

  $patch_uri = $archive_uri ? {
    undef   => $arcgis::globals::world_geocoder_archive_package_file ? {
      undef   => undef,
      default => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/patches/${archive_file}",
    },
    default => $archive_uri
  }

  file { $extract_path:
    ensure  => 'directory',
    owner   => $arcgis::globals::run_as_user,
    group   => $arcgis::globals::run_as_user_group,
    mode    => '0755',
    require => Class['arcgis::common'],
  }

  archive { $archive_package_file:
    path          => $archive_package_file,
    source        => $patch_uri,
    checksum      => $archive_sha1,
    checksum_type => 'sha1',
    extract       => true,
    extract_path  => $extract_path,
    creates       => $apply_script,
    cleanup       => false,
    user          => $arcgis::globals::run_as_user,
    group         => $arcgis::globals::run_as_user_group,
    temp_dir      => $arcgis::params::path_software_temp,
    require       => File[$extract_path],
  }

  $i_cmd = "sudo -u ${arcgis::globals::run_as_user} bash -c '${apply_script} -s ${patch_type_flag} -default && touch ${run_indicator}'"
  $i_path = '/bin:/sbin:/usr/bin:/usr/sbin'
  $i_user = 'root'
  $i_group = 'root'
  $i_umask = '022'
  $i_timeout = '7200'

  if $arcgis::globals::patch_install_use_facts {
    # These two ifs could be merged, but it's harder to read.
    if ! $::arcgis_installed_qfe_ids or ($::arcgis_installed_qfe_ids !~ Array[String]) or ! ($_qfe_id in $::arcgis_installed_qfe_ids) {
      exec { "${_qfe_id}_patch_install":
        command => $i_cmd,
        user    => $i_user,
        group   => $i_group,
        umask   => $i_umask,
        cwd     => $extract_path,
        path    => $i_path,
        timeout => $i_timeout,
        creates => $run_indicator,
        require => $patch_install_require,
      }
    }
  }

  if $arcgis::globals::patch_install_use_file_indicator {
    exec { "${_qfe_id}_patch_install":
      command => $i_cmd,
      user    => $i_user,
      group   => $i_group,
      umask   => $i_umask,
      cwd     => $extract_path,
      path    => $i_path,
      timeout => $i_timeout,
      creates => $run_indicator,
      require => $patch_install_require,
    }
  }
}
