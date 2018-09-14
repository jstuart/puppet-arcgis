# Manage ulimits for the ArcGIS service user
#
# @summary Manage ulimits for the ArcGIS service user
#
# @example
#   include arcgis::sercurity::limits
class arcgis::security::limits inherits arcgis::params {

  $filename = '/etc/security/limits.d/80-arcgis.conf'

  if $arcgis::globals::manage_ulimits {

    # switch on ensure to avoid template compilation when absent
    if $arcgis::globals::ensure == 'present' {
      $real_username     = $arcgis::globals::run_as_user
      $real_nofile_soft  = $arcgis::globals::ulimits_nofile_soft
      $real_nofile_hard  = $arcgis::globals::ulimits_nofile_hard
      $real_nproc_soft   = $arcgis::globals::ulimits_nproc_soft
      $real_nproc_hard   = $arcgis::globals::ulimits_nproc_hard
      $real_memlock_soft = $arcgis::globals::ulimits_memlock_soft
      $real_memlock_hard = $arcgis::globals::ulimits_memlock_hard
      $real_fsize_soft   = $arcgis::globals::ulimits_fsize_soft
      $real_fsize_hard   = $arcgis::globals::ulimits_fsize_hard
      $real_as_soft      = $arcgis::globals::ulimits_as_soft
      $real_as_hard      = $arcgis::globals::ulimits_as_hard

      file { $filename:
        ensure  => $arcgis::globals::ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}${filename}.erb")
      }
    } else {
      file { $filename:
        ensure  => $arcgis::globals::ensure,
      }
    }

  }
}
