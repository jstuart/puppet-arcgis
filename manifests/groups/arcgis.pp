# Manage the ArcGIS service user group
#
# @summary Manage the ArcGIS service user group
#
# @example
#   include arcgis::groups::arcgis
class arcgis::groups::arcgis inherits arcgis::params {

  if $arcgis::globals::manage_run_as_user_group {
    group { $arcgis::globals::run_as_user_group:
      ensure => $arcgis::globals::ensure,
      gid    => $arcgis::globals::run_as_user_gid,
    }
  }

}
