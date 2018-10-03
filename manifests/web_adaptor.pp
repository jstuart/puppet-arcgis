# Management of the ArcGIS Enterprise Web Adaptor extension
#
# @summary Management of the Enterprise Web Adaptor extension
#
# @example
#   include arcgis::web_adaptor
class arcgis::web_adaptor inherits arcgis::params {

    # Nothing will work without server
    include arcgis::server

    # Include java and tomcat here, as they serve as containers for our upstream dependencies
    include arcgis::tools::java
    include arcgis::tools::tomcat

    # TODO: Need checks for the following, which likely cause silent failures:
    # - available space in /tmp to grab the archive
    # - available space in /tmp for the installer to unpack itself and run
    # - ensure noexec not present on /tmp

    archive { $arcgis::globals::web_adaptor_archive_package_file:
      path          => $arcgis::params::web_adaptor_setup_archive,
      source        => $arcgis::globals::web_adaptor_archive_uri,
      checksum      => $arcgis::globals::web_adaptor_archive_package_sha1,
      checksum_type => 'sha1',
      extract       => true,
      extract_path  => $arcgis::params::path_unpack_parent,
      creates       => $arcgis::params::web_adaptor_setup_runtime,
      cleanup       => false,
      user          => $arcgis::globals::run_as_user,
      group         => $arcgis::globals::run_as_user_group,
      temp_dir      => $arcgis::params::path_software_temp,
      require       => Class['arcgis::server'],
    }

    # FIXME: this should use the a fact to determine whether it needs to run
    # FIXME: this can't run as the user itself because ulimits aren't detected; see PUP-6635
    exec { 'arcgis-web-adaptor-install':
      command => "sudo -u ${arcgis::globals::run_as_user} bash -c '${arcgis::params::web_adaptor_setup_runtime} -m silent -l yes -d \"${arcgis::params::path_base}\"'",
      cwd     => $arcgis::params::path_base,
      user    => 'root',
      group   => 'root',
      umask   => '027',
      path    => '/bin:/sbin:/usr/bin:/usr/sbin',
      timeout => '7200',
      creates => $arcgis::params::web_adaptor_war_file,
      notify  => Exec['arcgis-web-adaptor-configure'],
      require => [
        Archive[$arcgis::globals::web_adaptor_archive_package_file],
        Class['arcgis::tools::java'],
        Class['arcgis::tools::tomcat'],
      ],
    }

    file { $arcgis::params::web_adaptor_webapps_target:
      ensure  => 'link',
      target  => $arcgis::params::web_adaptor_war_file,
      notify  => Exec['arcgis-web-adaptor-configure'],
      require => Exec['arcgis-web-adaptor-install'],
    }

    # FIXME: the server uri here is hard coded in params
    # FIXME: it would be better if we could use a token here or something
    # FIXME: sleep to let webapp deploy
    exec { 'arcgis-web-adaptor-configure':
      command     => "sudo -u ${arcgis::globals::run_as_user} bash -c 'sleep 15; ${arcgis::params::web_adaptor_config_runtime} -m ${arcgis::globals::web_adaptor_mode} -w \"${arcgis::globals::web_adaptor_public_uri}\" -g \"${arcgis::params::server_uri_full}\" -u \"${arcgis::globals::psa_username}\" -p \"${arcgis::globals::psa_password}\" -a ${arcgis::globals::web_adaptor_enable_admin}'",
      cwd         => $arcgis::params::web_adaptor_tools_dir,
      user        => 'root',
      group       => 'root',
      umask       => '027',
      path        => '/bin:/sbin:/usr/bin:/usr/sbin',
      timeout     => '7200',
      refreshonly => true,
      require     => File[$arcgis::params::web_adaptor_webapps_target],
    }

}
