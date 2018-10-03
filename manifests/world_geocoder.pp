# Management of the ArcGIS World Geocoder extension
#
# @summary Management of the ArcGIS World Geocoder extension
#
# As far as I know Esri does not distribute World Geocoder in package form. We
# ended up taking the directory structure that they provided to us and turning
# it into a package that was named in a similar style to the other Esri
# packages. This package does not install, but instead gets unpacked into the
# 'content_folder' location, where it is then registered as a service within
# ArcGIS server by the provided script.  Notionally this registration could be
# done using the arcgis_service type.
#
# The structure of our package file looks roughly like this:
# | [d] LocatorData
# | [d] | World
# | [d] | | World
# | [f] | | | ...
# | [f] | | ...
# | [d] LocatorSD
# | [f] | ...
# | [d] Scripts
# | [f] | ...
# | [f] | PublishWorldGeocodeService.ini
# | [f] | PublishWorldGeocodeService.py
# | [d] | utils
# | [f] | | ...
#
# There is no top level container, so when the file is unpacked, the target
# directory, in this case 'content_folder' will get LocatorData, LocatorSD and
# Scripts directories.
#
# @example
#   include arcgis::world_geocoder
class arcgis::world_geocoder inherits arcgis::params {

    unless (
      $arcgis::globals::world_geocoder_archive_package_file and
      $arcgis::globals::world_geocoder_archive_package_sha1 and
      $arcgis::globals::world_geocoder_archive_uri
    ) {
      fail(
        'Use of the World Geocoder addon makes the following arcgis::globals required:\n' +
        '  # The filename of the package file, which will be used to create a URI if it isn ot provided\n' +
        '  String $world_geocoder_archive_package_file\n' +
        '  # The SHA1 hash of the package file\n' +
        '  String $world_geocoder_archive_package_sha1\n' +
        '  # The optional URI to completely override the package URI entirely\n' +
        '  Variant[Stdlib::Httpurl, Stdlib::Httpsurl] $archive_uri_world_geocoder'
      )
    }

    # Nothing will work without server
    include arcgis::server

    # Set the server property to the fully qualified domain name of the machine
    # running ArcGIS Server including the appropriate port for the URL scheme
    # specified as part of the protocol property. For example, if you're using
    # http for protocol, the value for the server property should be
    # gisserver.domain.com:6080. If you're using https for protocol, the value
    # for the server property should be gisserver.domain.com:6443.
    $server = "${arcgis::params::server_uri_fqdn}:${arcgis::params::server_uri_port}"
    $protocol = $arcgis::params::server_uri_protocol

    # Set the portal property to the fully qualified domain name of the machine
    # running Portal for ArcGIS. Be sure to include the port number, 7443, when
    # specifying the fully qualified domain name. For example, the value for the
    # portal property should be in the form portalserver.domain.com:7443. Make
    # sure that the protocol property is set to https and the server property is
    # set to the value that is appropriate for https. If ArcGIS Server is not
    # federated with a portal, leave the portal property blank.
    $portal = '' # FIXME: portal URI

    # Set the username property to the user name of the PSA user. If ArcGIS
    # Server is federated, the username property must be set to a user in the
    # portal with administrative privileges.
    $username = $arcgis::globals::psa_username

    # Set the password property to the PSA user password. If ArcGIS Server is
    # federated, set the password property to the password for the user in the
    # portal with administrative privileges.
    $password = $arcgis::globals::psa_password

    # Set the content_folder property to the folder containing the service data,
    # such as /data/GeocodeService.
    $content_folder = $arcgis::params::world_geocoder_content_dir

    # Set the edition property to the basic, standard, or advanced setting based
    # on the edition of the World Geocoder that you have licensed.
    $edition = $arcgis::globals::world_geocoder_edition

    file { $arcgis::params::world_geocoder_content_dir:
      ensure  => 'directory',
      owner   => $arcgis::globals::run_as_user,
      group   => $arcgis::globals::run_as_user_group,
      mode    => '0755', # FIXME: verify
      require => Class['Arcgis::Server'],
    }

    archive { $arcgis::globals::world_geocoder_archive_package_file:
      path          => $arcgis::params::world_geocoder_setup_archive,
      source        => $arcgis::globals::world_geocoder_archive_uri,
      checksum      => $arcgis::globals::world_geocoder_archive_package_sha1,
      checksum_type => 'sha1',
      extract       => true,
      extract_path  => $arcgis::params::world_geocoder_content_dir,
      creates       => $arcgis::params::world_geocoder_install_script,
      cleanup       => false,
      user          => $arcgis::globals::run_as_user,
      group         => $arcgis::globals::run_as_user_group,
      temp_dir      => $arcgis::params::path_software_temp,
      require       => File[$arcgis::params::world_geocoder_content_dir],
    }

    file { $arcgis::params::world_geocoder_config_file:
      ensure  => 'present',
      owner   => $arcgis::globals::run_as_user,
      group   => $arcgis::globals::run_as_user_group,
      mode    => '0644', # FIXME: verify
      content => template("${module_name}/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini"),
      require => Archive[$arcgis::globals::world_geocoder_archive_package_file],
    }

    exec { 'world-geocoder-install':
      command => "sudo -u ${arcgis::globals::run_as_user} bash -c '${arcgis::params::server_python_tool} ${arcgis::params::world_geocoder_install_script} && touch ${arcgis::params::world_geocoder_install_indicator}'",
      user    => 'root',
      group   => 'root',
      umask   => '022',
      cwd     => $arcgis::params::world_geocoder_scripts_dir,
      path    => "${arcgis::params::server_tools_dir}:/bin:/sbin:/usr/bin:/usr/sbin",
      timeout => '7200',
      creates => $arcgis::params::world_geocoder_install_indicator,
      require => File[$arcgis::params::world_geocoder_config_file],
    }
}
