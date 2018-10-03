# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include arcgis::tools::tomcat
class arcgis::tools::tomcat inherits arcgis::params {

  if $arcgis::globals::manage_tomcat {
    contain arcgis::tools::epel
    contain arcgis::tools::java

    class { 'tomcat':
    }

    tomcat::instance { 'arcgis':
      install_from_source => false,
      package_name        => 'tomcat',
      require             => [Class['arcgis::tools::epel'], Class['arcgis::tools::java']],
    }

    tomcat::service { 'arcgis':
      use_jsvc     => false,
      use_init     => true,
      service_name => 'tomcat',
      require      => Tomcat::Instance['arcgis'],
      subscribe    => Tomcat::Instance['arcgis'],
    }
  }

}
