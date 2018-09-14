# Manage the ArcGIS service user
#
# @summary Manage the ArcGIS service user
#
# @example
#   include arcgis::users::arcgis
class arcgis::users::arcgis inherits arcgis::params {
  include arcgis::groups::arcgis

  if $arcgis::globals::manage_run_as_user {
    $group_require = $arcgis::globals::manage_run_as_user_group ? { true => Group[$arcgis::globals::run_as_user_group], default => []}

    user { $arcgis::globals::run_as_user:
      ensure     => $arcgis::globals::ensure,
      uid        => $arcgis::globals::run_as_user_uid,
      gid        => $arcgis::globals::run_as_user_group,
      password   => $arcgis::globals::run_as_user_password,
      managehome => $arcgis::globals::run_as_user_manage_home,
      home       => $arcgis::globals::run_as_user_home,
      shell      => $arcgis::globals::run_as_user_shell,
      comment    => 'ArcGIS user account',
      require    => $arcgis::users::arcgis::group_require,
    }
  }
}
