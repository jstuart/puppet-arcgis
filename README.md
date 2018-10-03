
# Esri ArcGIS Puppet Module

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with arcgis](#setup)
    * [What arcgis affects](#what-arcgis-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with arcgis](#beginning-with-arcgis)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This module installs and configures Esri [ArcGIS Enterprise](https://www.esri.com/en-us/arcgis/products/arcgis-enterprise/overview) applications.

ArcGIS Enterprise is commercial software.  Important information regarding License and Services Terms of Use, Export Compliance, Data Attributions and Terms of Use, Privacy Policy and other legal concerns can be found on the [Esri Legal](https://www.esri.com/en-us/legal/overview) page.

This module supports ArcGIS Enterprise 10.4+ (to 10.6.1 at present).

## Setup

### This module can manage the following

* ArcGIS Server
* ArcGIS Web Adaptor
* ArcGIS Portal (future)
* ArcGIS Data Store (future)
* ArcGIS World Geocoder

### Requirements

You must acquire and make available all ArcGIS software and license files to this module using HTTPS or some other transport mechanism supported by the [archive](https://forge.puppet.com/puppet/archive) module.

This module assumes that you are performing an offline installation.  Interaction with online services such as authorization and patch management might work, but none of that interaction has been tested.

This module request the following Puppet modules:
* The [stdlib](https://forge.puppetlabs.com/puppetlabs/stdlib) Puppet library (4.24+).
* The [archive](https://forge.puppet.com/puppet/archive) Puppet library for archive retrieval and unpacking.
(optional).
* The [camptocamp/systemd](https://forge.puppet.com/camptocamp/systemd) Puppet library for systemd service management on EL7.

### Firewall management (future)

This module will support the management of ArcGIS service exposure using iptables on EL6/7 and firewalld on EL7.

If enabled, the following Puppet modules may be required:
* The [firewall](https://forge.puppet.com/puppetlabs/firewall) Puppet library for the management of iptables (optional).
* The [firewalld](https://forge.puppet.com/crayfishx/firewalld) Puppet library for the management of firewalld on EL7 (optional).

### Java management (optional)

This module will support the management of Java, as required by ArcGIS Web Adaptor.  Management is disabled by default because
the target audience for this module almost certainly manages Java already.  If the `arcgis::globals::manage_java` param is set
to false and you're using Web Adaptor, you must ensure your tooling installs and configures Java before the `arcgis::tools::java`
class.  That class will be required by anything that needs Java.

If enabled, the following Puppet modules will be required:
* The [java](https://forge.puppet.com/puppetlabs/java) Puppet library for the management of Java (optional).

### EPEL management (optional)

This module will support the management of EPEL, which is used by Tomcat and required only if Tomcat is enabled. Management is
disabled by default because the target audience for this module almost certainly manages EPEL already.  If the
`arcgis::globals::manage_epel` param is set to false and you're using Tomcat, you must ensure your tooling installs and
configures EPEL before the `arcgis::tools::epel` class.  That class will be required by anything that needs EPEL.

If enabled, the following Puppet modules will be required:
* The [epel](https://forge.puppet.com/stahnma/epel) Puppet library for the management of EPEL (optional).

### Tomcat management (optional)

This module will support the management of Tomcat, which is used by ArcGIS Web Adaptor. Management is disabled by default because
the target audience for this module almost certainly manages Tomcat already.  If the `arcgis::globals::manage_tomcat` param is set
to false and you're using Web Adaptor, you must ensure your tooling installs and configures Tomcat before the
`arcgis::tools::tomcat` class.  That class will be required by anything that needs Tomcat.

Note: You may need to use module version 1.7.0 or below to avoid [MODULES-6580](https://tickets.puppetlabs.com/browse/MODULES-6580) on EL based systems.

If enabled, the following Puppet modules will be required:
* The [tomcat](https://forge.puppet.com/puppetlabs/tomcat) Puppet library for the management of Tomcat (optional).

### Beginning with ArcGIS

To start, declare the `arcgis::globals` class to pass in any necessary configuration.  Declare the `arcgis::server` class to cause the server instance to be instantiated.

```puppet
class { 'arcgis::globals':
  version           => '10.5.1',
  archive_base_uri  => 'https://my.repository.server/arcgis',
  license_file_uri  => 'https://my.secret.server/arcgis/license-10.5.1.ecp',
}

class { 'arcgis::server': }
```

The module will:
* create a service user and group both named arcgis
* do any pre-installation configuration that is required
* download the server package from https://my.repository.server/arcgis/10.5.1/ArcGIS_Server_Linux_1051_156429.tar.gz
* install the server to /opt/arcgis/server
* authorize the server using the license file specified
* create a site backed by local directories in /opt/arcgis/data/server

## Usage

### Globals

All of the configuration parameters that can be changed are changed here.

TODO: fill out more info about common usage.

### Server

Inclusion of the server class will cause ArcGIS Server to be installed and configured.  Everything else this module does is centered around the ArcGIS Server system.

### World Geocoder

Inclusion of the World Geocoder class will cause the geocoder service to be installed and configured on the running Server instance.  If the Server class has not been installed, it will be included here using the values configured in globals, or defaults.

## Limitations

This module is in the very early stages of development.  All code, including APIs, are subject to change.

This module is built on and tested against Puppet 5.  Later versions of Puppet 4 should work.  Puppet 3 is not supported.

This module has ONLY been tested on RHEL 6.10 and 7.5.  It is safe to assume that other EL variants like CentOS and Oracle Linux will work, but your mileage may vary.  All other operating systems are not supported at this time.

## Development

TBD

## License

Copyright 2018 James Stuart

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Support

Please contact Esri for ArcGIS support.  Issues and contributions can be made using Github.
