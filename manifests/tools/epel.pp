# A class wrapping support for the management of EPEL.  If you have set
# arcgis::globals::manage_epel to false, and enabled the management of Tomcat
# you must ensure that EPEL is present and configured before this class, e.g.
# before => Class['arcgis::tools::epel']
#
# @summary A class wrapping support for the management of EPEL.
#
# @example
#   include arcgis::tools::epel
class arcgis::tools::epel inherits arcgis::params {

  if $arcgis::globals::manage_epel {
    contain epel
  }

}
