# Management of the ArcGIS Server service
#
# @summary Management of the ArcGIS Server service
#
# @example
#   include arcgis::server
class arcgis::server (

) inherits arcgis::params {

  contain arcgis::common

  if $arcgis::params::do_install_system_requirements {
    ensure_packages($arcgis::globals::external_package_list)
  }

  # TODO: Need checks for the following, which cause silent failures:
  # - available space in /tmp to grab the archive
  # - available space in /tmp for the installer to unpack itself and run
  # - ensure noexec not present on /tmp

  archive { $arcgis::globals::server_archive_package_file:
    path          => $arcgis::params::server_setup_archive,
    source        => $arcgis::globals::server_archive_uri,
    checksum      => $arcgis::globals::server_archive_package_sha1,
    checksum_type => 'sha1',
    extract       => true,
    extract_path  => $arcgis::params::path_unpack_parent,
    creates       => $arcgis::params::server_setup_runtime,
    cleanup       => false,
    user          => $arcgis::globals::run_as_user,
    group         => $arcgis::globals::run_as_user_group,
    temp_dir      => $arcgis::params::path_software_temp,
    require       => [Class['arcgis::common'], Package[$arcgis::globals::external_package_list]],
  }

  ##
  # TODO: The install and authorization stuff should almost certainly be moved
  # up a layer and re-implemented as a type so we can implement the same retry
  # logic that the Chef module uses.  That said, needing to use multiple retries
  # with randomized delays to work around problems with concurrent ops is
  # pretty unfortunate from a product perspective.
  ##

  # FIXME: this should use the a fact to determine whether it needs to run
  # FIXME: this can't run as the user itself because ulimits aren't detected; see PUP-6635
  # Note: this exec is constrained by creates on the start tool because the
  # parent directory will exist even if the install fails. We observed the
  # creation of /opt/arcgis/server/.Setup/ArcGISServer_InstallLog.log when
  # the install failed because of noexec on /tmp.
  exec { 'arcgis-server-install':
    # this could activate at install time, but given that we will likely need to reinstall the license, punt on that
    # -a \"${<activation file location>}\"
    command => "sudo -u ${arcgis::globals::run_as_user} bash -c '${arcgis::params::server_setup_runtime} -m silent -l yes -d \"${arcgis::params::path_base}\"'",
    cwd     => $arcgis::params::path_base,
    user    => 'root',
    group   => 'root',
    umask   => '027',
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    timeout => '7200',
    creates => $arcgis::params::server_start_tool,
    require => Archive[$arcgis::globals::server_archive_package_file],
  }

  # FIXME: we need a way to determine whether the product is installed
  #exec { 'arcgis-server-uninstall':
  #  command => "${arcgis::params::server_uninstall_runtime} -s"
  #  cwd     => $arcgis::params::path_base,
  #  user    => 'root',
  #  group   => 'root',
  #  umask   => '027',
  #  path    => '/bin:/sbin:/usr/bin:/usr/sbin',
  #  timeout => '7200',
  #}

  # The Chef routine has a sleep(180) after the install

  # TODO: check to see if this has the same sudo problem as above
  # Output of the check when unauthorized is:
  ##
  # [root@arcgis ~]# sudo -u arcgis /opt/arcgis/server/tools/authorizeSoftware -s
  # --------------------------------------------------------------------------
  # Starting the ArcGIS Software Authorization Wizard
  #
  # Run this script with -h for additional information.
  # --------------------------------------------------------------------------
  # Not Authorized.
  # [root@arcgis ~]# echo $?
  # 0
  ##
  #
  # Output of the check when authorized is:
  ##
  # [root@arcgis ~]# sudo -u arcgis /opt/arcgis/server/tools/authorizeSoftware -s
  # --------------------------------------------------------------------------
  # Starting the ArcGIS Software Authorization Wizard
  #
  # Run this script with -h for additional information.
  # --------------------------------------------------------------------------
  # Product          Ver   ECP#           Expires
  # -------------------------------------------------
  # svradv           105   ecpXXXXXXXXX   30-sep-2018
  # svrenterprise    105   ecpXXXXXXXXX   30-sep-2018
  # networkserver    105   ecpXXXXXXXXX   30-sep-2018
  # arcsdeserver     105   ecpXXXXXXXXX   30-sep-2018
  # svradv_4         105   ecpXXXXXXXXX   30-sep-2018
  # [root@arcgis ~]# echo $?
  # 0
  ##

  $authorize_umask = '027'
  $authorize_path = '/bin:/sbin:/usr/bin:/usr/sbin'
  $authorize_timeout = '7200'
  $authorize_require = Exec['arcgis-server-install']

  # Re-authorize on license file change.  This also runs on first deployment
  # but will not execute on subsequent runs unless the license file changes.
  exec { 'arcgis-server-reauthorize':
    command     => "${arcgis::params::server_authorization_tool} -f ${arcgis::params::license_file}",
    cwd         => $arcgis::params::path_base,
    user        => $arcgis::globals::run_as_user,
    group       => $arcgis::globals::run_as_user_group,
    umask       => $authorize_umask,
    path        => $authorize_path,
    timeout     => $authorize_timeout,
    refreshonly => true,
    require     => $authorize_require,
    before      => Exec['arcgis-server-authorize'],
    subscribe   => Archive[$arcgis::params::license_file],
  }

  # Perform initial authorization if the system is not already authorized.
  # This should really only handle situations in which the server has been
  # de-authorized (or authorization has failed in previous runs) and the
  # license file has not changed. Running after the reauthorize exec should
  # prevent duplicate runs as the unless conditional will constrain this one.
  exec { 'arcgis-server-authorize':
    command => "${arcgis::params::server_authorization_tool} -f ${arcgis::params::license_file}",
    cwd     => $arcgis::params::path_base,
    user    => $arcgis::globals::run_as_user,
    group   => $arcgis::globals::run_as_user_group,
    umask   => $authorize_umask,
    path    => $authorize_path,
    timeout => $authorize_timeout,
    unless  => "bash -c 'output=\"$(${arcgis::params::server_authorization_tool} -s)\" && echo \$output | grep -qv \"Not Authorized\"'",
    require => $authorize_require,
  }

  case $::service_provider {
    'systemd': {
      systemd::unit_file { 'arcgisserver.service':
        ensure  => 'present',
        content => template("${module_name}${arcgis::params::server_systemd_service_file}.erb"),
        require => Exec['arcgis-server-install'],
        before  => Service['arcgisserver'],
        notify  => Service['arcgisserver'],
      }
    }
    'redhat': {
      file { $arcgis::params::server_sysv_service_file:
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template("${module_name}${arcgis::params::server_sysv_service_file}.erb"),
        require => Exec['arcgis-server-install'],
        before  => Service['arcgisserver'],
        notify  => Service['arcgisserver'],
      }
    }
    default: {
      # noop; will have failed in globals
    }
  }

  # TODO: status and restart?
  service { 'arcgisserver':
    ensure  => 'running',
    enable  => true,
    require => Exec['arcgis-server-install'],
  }

  arcgis_site { 'arcgis':
    ensure             => 'present',
    username           => $arcgis::globals::psa_username,
    password           => $arcgis::globals::psa_password,
    configstoretype    => 'FILESYSTEM',
    configdir          => $arcgis::globals::server_config_dir,
    logdir             => $arcgis::globals::server_log_dir,
    serverloglevel     => $arcgis::globals::server_log_level,
    logmaxerrorreports => $arcgis::globals::server_max_error_reports,
    logmaxfileage      => $arcgis::globals::server_max_log_file_age,
    require            => Service['arcgisserver'],
  }

  arcgis_directory { 'arcgiscache':
    ensure        => 'present',
    username      => $arcgis::globals::psa_username,
    password      => $arcgis::globals::psa_password,
    physicalpath  => $arcgis::globals::server_cache_dir,
    directorytype => 'CACHE',
    cleanupmode   => 'NONE',
    maxfileage    => 0,
    description   => 'Stores tile caches used by map, globe, and image services for rapid performance.',
    require       => Arcgis_site['arcgis'],
  }

  arcgis_directory { 'arcgisjobs':
    ensure        => 'present',
    username      => $arcgis::globals::psa_username,
    password      => $arcgis::globals::psa_password,
    physicalpath  => $arcgis::globals::server_jobs_dir,
    directorytype => 'JOBS',
    cleanupmode   => 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
    maxfileage    => $arcgis::globals::server_max_jobs_file_age,
    description   => 'Stores results and other information from geoprocessing services.',
    require       => Arcgis_site['arcgis'],
  }

  arcgis_directory { 'arcgisoutput':
    ensure        => 'present',
    username      => $arcgis::globals::psa_username,
    password      => $arcgis::globals::psa_password,
    physicalpath  => $arcgis::globals::server_output_dir,
    directorytype => 'OUTPUT',
    cleanupmode   => 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
    maxfileage    => $arcgis::globals::server_max_output_file_age,
    description   => 'Stores various information generated by services, such as map images.',
    require       => Arcgis_site['arcgis'],
  }

  arcgis_directory { 'arcgissystem':
    ensure        => 'present',
    username      => $arcgis::globals::psa_username,
    password      => $arcgis::globals::psa_password,
    physicalpath  => $arcgis::globals::server_system_dir,
    directorytype => 'SYSTEM',
    cleanupmode   => 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
    maxfileage    => $arcgis::globals::server_max_system_file_age, # FIXME: allow override
    description   => 'Stores directories and files used internally by ArcGIS Server.',
    require       => Arcgis_site['arcgis'],
  }

}
