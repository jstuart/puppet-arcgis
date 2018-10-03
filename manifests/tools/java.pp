# A class wrapping support for the management of Java.  If you have set
# arcgis::globals::manage_java to false, you must ensure that Java 8 is
# present and configured before this class, e.g.
# before => Class['arcgis::tools::java']
#
# @summary A class wrapping support for the management of Java.
#
# @example
#   include arcgis::tools::java
class arcgis::tools::java inherits arcgis::params {

  if $arcgis::globals::manage_java {
    # detect java 8 but don't upgrade if it's already there
    if $::java_major_version and versioncmp($::java_major_version, '8') >= 0 {
      $_version = "1.${::java_major_version}.0.${::java_patch_level}"
    } else {
      $_version = 'latest'
    }

    class { 'java':
      distribution => 'jre',
      version      => $_version,
    }
  }

}
