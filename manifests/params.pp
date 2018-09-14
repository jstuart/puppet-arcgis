# Base parameters for ArcGIS components
#
# @summary Base parameters for ArcGIS components
#
# @example
#   include arcgis::params
class arcgis::params inherits arcgis::globals {
  # Set a static path so we can drop data out there for facts to pick up
  $static_info_dir = '/etc/arcgis'
  $static_info_filename = 'puppet_data.json'
  $static_info_path = "${static_info_dir}/${static_info_filename}"

  # Define the versions we know how to support
  $supported_versions = [
    '10.4',
    '10.4.1',
    '10.5',
    '10.5.1',
    '10.6',
    '10.6.1',
  ]

  # Current version information
  $real_version = $arcgis::globals::version
  $do_install_system_requirements = $arcgis::globals::install_system_requirements

  # Base paths off of $install_dir
  $path_base              = $arcgis::globals::install_dir
  $path_arcgis            = "${arcgis::params::path_base}/arcgis"
  $path_software          = "${arcgis::params::path_arcgis}/software"
  $path_software_archives = "${arcgis::params::path_software}/archives"
  $path_software_setup    = "${arcgis::params::path_software}/setup"
  $path_software_license  = "${arcgis::params::path_software}/license"
  $path_software_temp     = "${arcgis::params::path_software}/tmp"

  # Archive related path
  $path_archive_parent = "${arcgis::params::path_software_archives}/${arcgis::params::real_version}"
  $path_unpack_parent  = "${arcgis::params::path_software_setup}/${arcgis::params::real_version}"

  # License path
  $license_file = "${arcgis::params::path_software_license}/${arcgis::globals::license_file_filename}"

  # Hard coded directories into which the installers will put software
  # given a base install path of $install_dir.
  $server_install_subdir      = 'arcgis/server'
  $web_adaptor_install_subdir = "arcgis/webadaptor${arcgis::params::real_version}"
  $portal_install_subdir      = 'arcgis/portal'
  $data_store_install_subdir  = 'arcgis/datastore'

  # The actual install targets for the products
  $path_server_install       = "${arcgis::params::path_base}/${arcgis::params::server_install_subdir}"
  $path_web_adaptor_install  = "${arcgis::params::path_base}/${arcgis::params::web_adaptor_install_subdir}"
  $path_portal_install       = "${arcgis::params::path_base}/${arcgis::params::portal_install_subdir}"
  $path_data_store_install   = "${arcgis::params::path_base}/${arcgis::params::data_store_install_subdir}"

  # Server Paths
  $server_start_tool             = "${arcgis::params::path_server_install}/startserver.sh"
  $server_stop_tool              = "${arcgis::params::path_server_install}/stopserver.sh"
  $server_tools_dir              = "${arcgis::params::path_server_install}/tools"
  $server_authorization_tool     = "${arcgis::params::server_tools_dir}/authorizeSoftware"
  $server_python_tool            = "${arcgis::params::server_tools_dir}/python"
  $server_local_directories_root = "${arcgis::params::path_server_install}/usr"
  $server_setup_archive          = "${arcgis::params::path_archive_parent}/${arcgis::globals::server_archive_package_file}"
  $server_setup_runtime          = "${arcgis::params::path_software_setup}/${arcgis::params::real_version}/ArcGISServer/Setup"
  $server_uninstall_runtime      = "${arcgis::params::path_server_install}/uninstall_ArcGISServer"
  $server_log_dir                = '/var/log/arcgis/server'
  $server_sysv_service_file      = '/etc/rc.d/init.d/arcgisserver'
  #$server_sysv_service_source    = "${arcgis::params::path_server_install}/framework/etc/scripts/arcgisserver"
  $server_systemd_service_file   = '/etc/systemd/system/arcgisserver.service'
  #$server_systemd_service_source = "${arcgis::params::path_server_install}/framework/etc/scripts/arcgisserver.service"

  # Web adaptor Paths
  $web_adaptor_setup_archive = "${arcgis::params::path_archive_parent}/${arcgis::globals::web_adaptor_archive_package_file}"
  $web_adpater_setup_runtime = "${arcgis::params::path_software_setup}/${arcgis::params::real_version}/WebAdaptor/Setup"
  $web_adaptor_log_dir       = '/var/log/arcgis/webadaptor'

  # Portal Paths
  $portal_start_tool             = "${arcgis::params::path_portal_install}/startportal.sh"
  $portal_stop_tool              = "${arcgis::params::path_portal_install}/stopportal.sh"
  $portal_authorization_tool     = "${arcgis::params::path_portal_install}/tools/authorizeSoftware"
  $portal_local_directories_root = "${arcgis::params::path_portal_install}/usr/arcgisportal"
  $portal_setup_archive          = "${arcgis::params::path_archive_parent}/${arcgis::globals::portal_archive_package_file}"
  $portal_setup_runtime          = "${arcgis::params::path_software_setup}/${arcgis::params::real_version}/PortalForArcGIS/Setup"
  $portal_log_dir                = '/var/log/arcgis/portal'

  # Datastore Paths
  $data_store_start_tool             = "${arcgis::params::path_data_store_install}/startserver.sh"
  $data_store_stop_tool              = "${arcgis::params::path_data_store_install}/stopserver.sh"
  $data_store_authorization_tool     = "${arcgis::params::path_data_store_install}/tools/authorizeSoftware"
  $data_store_local_directories_root = "${arcgis::params::path_data_store_install}/usr"
  $data_store_setup_archive          = "${arcgis::params::path_archive_parent}/${arcgis::globals::data_store_archive_package_file}"
  $data_store_setup_runtime          = "${arcgis::params::path_software_setup}/${arcgis::params::real_version}/ArcGISDataStore_Linux/Setup"
  $data_store_log_dir                = '/var/log/arcgis/datastore'

  # World Geocoder Paths
  $world_geocoder_setup_archive     = "${arcgis::params::path_archive_parent}/${arcgis::globals::world_geocoder_archive_package_file}"
  $world_geocoder_content_dir       = "${arcgis::globals::world_geocoder_parent_dir}/GeocodeService"
  $world_geocoder_scripts_dir       = "${arcgis::params::world_geocoder_content_dir}/Scripts"
  $world_geocoder_config_file       = "${arcgis::params::world_geocoder_scripts_dir}/PublishWorldGeocodeService.ini"
  $world_geocoder_install_script    = "${arcgis::params::world_geocoder_scripts_dir}/PublishWorldGeocodeService.py"
  $world_geocoder_install_indicator = "${arcgis::params::world_geocoder_content_dir}/.installed"
}
