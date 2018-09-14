# Manage the local firewall
#
# @summary Manage the local firewall
#
# @example
#   include arcgis::config::firewall
class arcgis::config::firewall inherits arcgis::params {

  if $arcgis::globals::manage_firewall {
    case $::osfamily {
      /^RedHat/: {
        case $::operatingsystemrelease {
          /^7./: {
            # FIXME firewalld config
          }
          /^6./: {
            firewall { '500 Allow access to ArcGIS Server ports':
              dport  => $arcgis::globals::firewall_allowed_ports,
              proto  => tcp,
              action => accept,
            }
          }
        }
      }
    }
  }
}
