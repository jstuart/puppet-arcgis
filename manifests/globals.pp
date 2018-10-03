# Global settings for all ArcGIS components
#
# @summary Global settings for all ArcGIS components
#
# @example
#   include arcgis::globals
class arcgis::globals (
  Enum['absent', 'present'] $ensure = 'present',
  String $version                    = '10.6.1',

  # Archive package location
  Variant[Stdlib::Httpurl, Stdlib::Httpsurl] $archive_base_uri                  = 'https://localhost',
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri_server      = undef,
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri_web_adaptor = undef,
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri_portal      = undef,
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri_data_store  = undef,

  # License file location
  Variant[Stdlib::Httpurl, Stdlib::Httpsurl] $license_file_uri = 'https://localhost/arcgis/authorization.ecp',
  String $license_file_sha1                                    = '1234567890123456789012345678901234567890',

  # Install options
  Stdlib::Absolutepath $install_dir    = '/opt',
  Boolean $install_system_requirements = true,

  # Service user
  String $run_as_user       = 'arcgis',
  String $run_as_user_group = 'arcgis',

  # Management of the service user
  Boolean $manage_run_as_user                       = true,
  Variant[Boolean, String] $run_as_user_password    = false,
  Boolean $run_as_user_manage_home                  = true,
  Optional[Stdlib::Absolutepath] $run_as_user_home  = '/home/arcgis',
  Optional[Stdlib::Absolutepath] $run_as_user_shell = '/bin/bash', # FIXME does this need to be interactive?
  Optional[Integer] $run_as_user_uid                = undef,

  # Management of the service user group
  Boolean $manage_run_as_user_group  = true,
  Optional[Integer] $run_as_user_gid = undef,

  # Management of ulimit settings for the service user
  Boolean $manage_ulimits                        = true,
  Variant[Integer, String] $ulimits_nofile_hard  = 65536,
  Variant[Integer, String] $ulimits_nofile_soft  = 65536,
  Variant[Integer, String] $ulimits_nproc_hard   = 25059,
  Variant[Integer, String] $ulimits_nproc_soft   = 25059,
  Variant[Integer, String] $ulimits_memlock_hard = 'unlimited',
  Variant[Integer, String] $ulimits_memlock_soft = 'unlimited',
  Variant[Integer, String] $ulimits_fsize_hard   = 'unlimited',
  Variant[Integer, String] $ulimits_fsize_soft   = 'unlimited',
  Variant[Integer, String] $ulimits_as_hard      = 'unlimited',
  Variant[Integer, String] $ulimits_as_soft      = 'unlimited',

  # Management of the local firewalld
  Boolean $manage_firewall                               = true,
  Array[Variant[String,Integer]] $firewall_allowed_ports = [1098, '4000-4004', 6006, 6080, 6099, 6443],

  # Management of Java
  # If this is false, you must ensure that Java 8 is present Before => [arcgis::tools::java]
  Boolean $manage_java = false,

  # Management of Tomcat
  Boolean $manage_tomcat = false,

  # Management of EPEL
  # If this is false, and you are using Tomcat, you must ensure EPEL is available
  # Before => [arcgis::tools::epel]
  Boolean $manage_epel = false,

  # Service autostart
  Boolean $configure_autostart                       = true,
  Optional[Boolean] $configure_autostart_server      = undef,
  Optional[Boolean] $configure_autostart_web_adaptor = undef,
  Optional[Boolean] $configure_autostart_portal      = undef,
  Optional[Boolean] $configure_autostart_data_store  = undef,

  # Base data directory
  Stdlib::Absolutepath $data_base_dir = '/opt/arcgis/data',

  # Server data directories
  Optional[Stdlib::Absolutepath] $server_data_base_dir   = undef,
  Optional[Stdlib::Absolutepath] $server_data_cache_dir  = undef,
  Optional[Stdlib::Absolutepath] $server_data_jobs_dir   = undef,
  Optional[Stdlib::Absolutepath] $server_data_output_dir = undef,
  Optional[Stdlib::Absolutepath] $server_data_system_dir = undef,
  Optional[Stdlib::Absolutepath] $server_data_log_dir    = undef,
  Optional[Stdlib::Absolutepath] $server_data_config_dir = undef,

  String $psa_username = 'admin',
  String $psa_password = 'admin', # TODO: should this really be defaulted?

  # The server log level
  Enum['OFF', 'SEVERE', 'WARNING', 'INFO', 'FINE', 'VERBOSE', 'DEBUG'] $server_log_level = 'INFO',
  # The number of error reports to keep
  Integer $server_max_error_reports = 10,
  # The number of days to keep log files
  Integer $server_max_log_file_age = 90,
  # The max age of jobs files before they're cleaned up
  Integer $server_max_jobs_file_age = 360,
  # The max age of output files before they're cleaned up
  Integer $server_max_output_file_age = 10,
  # The max age of system files before they're cleaned up
  Integer $server_max_system_file_age = 1440,

  ##
  # Patch configuration
  ##
  # Note: if both of the flags below are true, the patch install may happen
  # zero, one, or two times during a puppet run.
  #
  # Use the discovered facts to determine what patches should be applied
  Boolean $patch_install_use_facts = true,
  # Use the file dropped after initial patch installation to determine what
  # patches should be applied
  Boolean $patch_install_use_file_indicator = false,

  ##
  # Web Adaptor Params
  ##
  Enum['server', 'portal'] $web_adaptor_mode                         = 'server',
  Variant[Stdlib::Httpurl, Stdlib::Httpsurl] $web_adaptor_public_uri = 'http://localhost:8080/arcgis/webadaptor',
  # Allow admin endpoints to be accessed through the web adaptor?
  Boolean $web_adaptor_enable_admin                                  = false,
  Optional[String] $web_adaptor_webapps_dir                          = undef,

  ##
  # World Geocoder Params
  ##
  #
  # The filename which is required for local storage and will be used to create
  # a archive package URI if it is not provided.
  String $world_geocoder_archive_package_file                                      = 'World_Geocoder_for_ArcGIS_1051.tar.gz',
  # The SHA1 hash of the package file
  String $world_geocoder_archive_package_sha1                                      = '20ecbe593b3a7b452dd9e4dba636e33170072fad',
  # The optional URI to completely override the package location
  Optional[Variant[Stdlib::Httpurl, Stdlib::Httpsurl]] $archive_uri_world_geocoder = undef,
  # The optional override for the World Geocoder content_folder parent. This
  # defaults to the value of $data_base_dir unless specified. If you override
  # this you must manage the specified directory yourself and ensure it is
  # present prior to the execution of Class[Arcgis::World_geocoder].
  Optional[Stdlib::Absolutepath] $world_geocoder_data_base_dir                     = undef,
  # The edition of World Geocoder to enable
  Enum['basic', 'standard', 'advanced', 'test'] $world_geocoder_edition            = 'advanced',

  ) {

  case $::osfamily {
    /^RedHat/: {

      # Grab our versions
      case $arcgis::globals::version {
        '10.6.1': {
          $server_archive_package_file = 'ArcGIS_Server_Linux_1061_164044.tar.gz'
          $server_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_1061_164057.tar.gz'
          $web_adaptor_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_1061_164055.tar.gz'
          $portal_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_1061_164056.tar.gz'
          $data_store_archive_package_sha1 = '1234567890123456789012345678901234567890'
        }
        '10.6': {
          $server_archive_package_file = 'ArcGIS_Server_Linux_106_159989.tar.gz'
          $server_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_106_161911.tar.gz'
          $web_adaptor_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_106_161809.tar.gz'
          $portal_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_106_161810.tar.gz'
          $data_store_archive_package_sha1 = '1234567890123456789012345678901234567890'
        }
        '10.5.1': {
          $server_archive_package_file = 'ArcGIS_Server_Linux_1051_156429.tar.gz'
          $server_archive_package_sha1 = 'b2a956a5d62770ee22f7de063bbd52a209ea94bb'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_1051_156442.tar.gz'
          $web_adaptor_archive_package_sha1 = '67fa566d67c1cd3880edb1cc65021360cc8db998'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_1051_156440.tar.gz'
          $portal_archive_package_sha1 = '854747388f1fec536f6a55589a7b8b7ebb5f0735'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_1051_156441.tar.gz'
          $data_store_archive_package_sha1 = '3ec2781350c0e4f78906769bc317bc643db2d50b'
        }
        '10.5': {
          $server_archive_package_file = 'ArcGIS_Server_Linux_105_154052.tar.gz'
          $server_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_105_154055.tar.gz'
          $web_adaptor_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_105_154053.tar.gz'
          $portal_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_105_154054.tar.gz'
          $data_store_archive_package_sha1 = '1234567890123456789012345678901234567890'
        }
        '10.4.1': {
          $server_archive_package_file = 'ArcGIS_for_Server_Linux_1041_151978.tar.gz'
          $server_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_1041_152000.tar.gz'
          $web_adaptor_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_1041_151999.tar.gz'
          $portal_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_1041_152011.tar.gz'
          $data_store_archive_package_sha1 = '1234567890123456789012345678901234567890'
        }
        '10.4': {
          $server_archive_package_file = 'ArcGIS_for_Server_Linux_104_149446.tar.gz'
          $server_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $web_adaptor_archive_package_file = 'Web_Adaptor_Java_Linux_104_149448.tar.gz'
          $web_adaptor_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $portal_archive_package_file = 'Portal_for_ArcGIS_Linux_104_149447.tar.gz'
          $portal_archive_package_sha1 = '1234567890123456789012345678901234567890'

          $data_store_archive_package_file = 'ArcGIS_DataStore_Linux_104_149449.tar.gz'
          $data_store_archive_package_sha1 = '1234567890123456789012345678901234567890'
        }
        default: {
          fail("Unsupported ArcGIS version: ${version}")
        }
      }

      $external_required_packages_rhel = [
        'fontconfig',
        'freetype',
        'gettext',
        'libxkbfile',
        'libXtst',
        'libXrender',
        'dos2unix'
      ]

      case $::operatingsystemrelease {
        /^7\./: {
          $external_package_list = $arcgis::globals::install_system_requirements ? {
            true    => $arcgis::globals::external_required_packages_rhel,
            default => [],
          }
          $web_adaptor_default_webapps_dir = '/usr/share/tomcat/webapps'
        }
        /^6\./: {
          $external_package_list = $arcgis::globals::install_system_requirements ? {
            true    => $arcgis::globals::external_required_packages_rhel,
            default => [],
          }
          $web_adaptor_default_webapps_dir = '/var/lib/tomcat/webapps'
        }
        default: {
          fail('This module only supports EL 6 and 7 variants')
        }
      }
    }
    /^[Ww]indows/: {
      fail("This module doesn't support Windows yet")
    }
    default: {
      fail('This module only supports EL 6 and 7 variants')
    }
  }

  # Sanity check to make sure the required stuff made it through
  [
    $arcgis::globals::server_archive_package_file,
    $arcgis::globals::server_archive_package_sha1,
    $arcgis::globals::web_adaptor_archive_package_file,
    $arcgis::globals::web_adaptor_archive_package_sha1,
    $arcgis::globals::portal_archive_package_file,
    $arcgis::globals::portal_archive_package_sha1,
    $arcgis::globals::data_store_archive_package_file,
    $arcgis::globals::data_store_archive_package_sha1,
    $arcgis::globals::external_package_list,
  ].each | Integer $index, $value | {
    if $value == undef {
      fail ("Required variable not found at position ${index}. This indicates a module code problem.")
    }
  }

  $server_archive_uri = $arcgis::globals::archive_uri_server ? {
    undef   => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/${arcgis::globals::server_archive_package_file}",
    default => $arcgis::globals::archive_uri_server
  }

  $web_adaptor_archive_uri = $arcgis::globals::archive_uri_web_adaptor ? {
    undef   => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/${arcgis::globals::web_adaptor_archive_package_file}",
    default => $arcgis::globals::archive_uri_web_adaptor
  }

  $portal_archive_uri = $arcgis::globals::archive_uri_portal ? {
    undef   => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/${arcgis::globals::portal_archive_package_file}",
    default => $arcgis::globals::archive_uri_portal
  }

  $data_store_archive_uri = $arcgis::globals::archive_uri_data_store ? {
    undef   => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/${arcgis::globals::data_store_archive_package_file}",
    default => $arcgis::globals::archive_uri_data_store
  }

  $world_geocoder_archive_uri = $arcgis::globals::archive_uri_world_geocoder ? {
    undef   => $arcgis::globals::world_geocoder_archive_package_file ? {
      undef   => undef,
      default => "${arcgis::globals::archive_base_uri}/${arcgis::globals::version}/${arcgis::globals::world_geocoder_archive_package_file}",
    },
    default => $arcgis::globals::archive_uri_world_geocoder
  }

  $license_file_filename = basename($arcgis::globals::license_file_uri)

  # Service settings
  $server_autostart      = pick($arcgis::globals::configure_autostart_server, $arcgis::globals::configure_autostart, true)
  $web_adpater_autostart = pick($arcgis::globals::configure_autostart_web_adaptor, $arcgis::globals::configure_autostart, true)
  $portal_autostart      = pick($arcgis::globals::configure_autostart_portal, $arcgis::globals::configure_autostart, true)
  $data_store_autostart  = pick($arcgis::globals::configure_autostart_data_store, $arcgis::globals::configure_autostart, true)

  # User field checks
  if (
    ($arcgis::globals::run_as_user_password =~ Boolean and $arcgis::globals::run_as_user_password == true)
    or
    ($arcgis::globals::run_as_user_password =~ String and ! ($arcgis::globals::run_as_user_password =~ /^\$[56]\$/))
  ) {
    fail('The value for $run_as_user_password must be either boolean false or a SHA256/SHA512 password hash.')
  }

  $server_base_data_dir = $arcgis::globals::server_data_base_dir ? {
    undef   => "${arcgis::globals::data_base_dir}/server",
    default => $arcgis::globals::server_data_base_dir
  }

  $server_cache_dir = $arcgis::globals::server_data_cache_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/cache",
    default => $arcgis::globals::server_data_cache_dir
  }

  $server_jobs_dir = $arcgis::globals::server_data_jobs_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/jobs",
    default => $arcgis::globals::server_data_jobs_dir
  }

  $server_output_dir = $arcgis::globals::server_data_output_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/output",
    default => $arcgis::globals::server_data_output_dir
  }

  $server_system_dir = $arcgis::globals::server_data_system_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/system",
    default => $arcgis::globals::server_data_system_dir
  }

  $server_log_dir = $arcgis::globals::server_data_log_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/logs",
    default => $arcgis::globals::server_data_log_dir
  }

  $server_config_dir = $arcgis::globals::server_data_config_dir ? {
    undef   => "${arcgis::globals::server_base_data_dir}/config-store",
    default => $arcgis::globals::server_data_config_dir
  }

  $world_geocoder_parent_dir = $arcgis::globals::world_geocoder_data_base_dir ? {
    undef   => $arcgis::globals::data_base_dir,
    default => $arcgis::globals::world_geocoder_data_base_dir,
  }

  case $::service_provider {
    'systemd': {
      # supported; noop
    }
    'redhat': {
      # supported; noop
    }
    default: {
      fail("This module only supports 'systemd' and 'redhat' service providers; '${::service_provider}' is active on this system.")
    }
  }

  if empty($arcgis::globals::psa_username) {
    fail ('The psa_username is required.')
  }

  if empty($arcgis::globals::psa_password) {
    fail ('The psa_password is required.')
  }

  $web_adaptor_webapps_deploy_dir = $arcgis::globals::web_adaptor_webapps_dir ? {
    undef   => $arcgis::globals::web_adaptor_default_webapps_dir,
    default => $arcgis::globals::web_adaptor_webapps_dir,
  }
}
