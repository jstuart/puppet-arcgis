$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', '..'))

require 'puppet/provider/arcgis_rest_api'

##
# https://developers.arcgis.com/rest/enterprise-administration/server/site.htm
#
# = Site =
# List: Singleton
# Create: http://server:port/arcgis/admin/createNewSite?f=json [POST]
# Retrieve: http://server:port/arcgis/admin/?f=json [GET] !! IMPORTANT: the trailing / is required!
# Update: There is no site update API; use config store, directories, etc.
# Delete: http://server:port/arcgis/admin/deleteSite?f=json [POST]
#
# = Configuration Store =
# List: Singleton
# Create: There is no configuration store create API; use site.
# Retrieve: http://server:port/arcgis/admin/system/configstore?f=json [GET]
# Update: http://server:port/arcgis/admin/system/configstore/edit?f=json [POST]
# Delete: There is no configuration store delete API; use site.
#
# = Log Settings =
# List: Singleton
# Create: There is no log settings create API; use site.
# Retrieve: http://server:port/arcgis/admin/logs/settings?f=json [GET]
# Update: http://server:port/arcgis/admin/logs/settings/edit?f=json [POST]
# Delete: There is no log settings delete API; use site.
#
#
# Before site creation:
##
# [james@arcgis ~]$ curl -i http://localhost:6080/arcgis/admin/?f=json
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 183
# Date: Fri, 24 Aug 2018 15:25:29 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Server machine 'ARCGIS.INTERNAL.LOCAL' does not participate in any Site. Create a new Site or join an existing Site."
#   ],
#   "code": 404,
#   "acceptLanguage": null
# }
##
#
# Before AND after site creation without authorization without the trailing slash
##
# [james@arcgis ~]$ curl -i http://localhost:6080/arcgis/admin?f=json
# HTTP/1.1 302 Found
# Location: http://localhost:6080/arcgis/admin/?f=json
# Transfer-Encoding: chunked
# Date: Thu, 06 Sep 2018 17:22:23 GMT
# Server:
#
##
#
# After site creation without authorization:
##
# [james@arcgis ~]$ curl -i http://localhost:6080/arcgis/admin/?f=json
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 144
# Date: Fri, 31 Aug 2018 20:14:17 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
#   ],
#   "code": 499
# }
##
#
# After site creation with authorization:
##
# [james@arcgis ~]$ curl -i 'http://localhost:6080/arcgis/admin/?f=json&token=...'
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 182
# Date: Thu, 30 Aug 2018 20:18:02 GMT
# Server:
#
# {
#   "resources": [
#     "machines",
#     "clusters",
#     "system",
#     "services",
#     "security",
#     "data",
#     "uploads",
#     "logs",
#     "mode",
#     "usagereports"
#   ],
#   "currentVersion": 10.51,
#   "fullVersion": "10.5.1",
#   "acceptLanguage": null
# }
##
#
# Create site before authorization:
##
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 183
# Date: Fri, 24 Aug 2018 15:25:29 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Failed to create the site. The machine does not have a valid license. Please authorize ArcGIS Server by running the authorizeSoftware script found under '/opt/arcgis/server/tools'."
#   ],
#   "code": 500
# }
##
#
# Successful site creation
##
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 20
# Date: Thu, 30 Aug 2018 20:06:23 GMT
# Server:
#
# {"status":"success"}
##
#
# Site deletion
##
# [james@arcgis ~]$ curl -XPOST -i 'http://localhost:6080/arcgis/admin/deleteSite?f=json&token=...'
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 20
# Date: Thu, 30 Aug 2018 20:21:21 GMT
# Server:
#
# {"status":"success"}
##
#
# Log settings retrieval - unauthenticated
##
# [james@arcgis ~]$ curl -XGET -is http://localhost:6080/arcgis/admin/logs/settings?f=json
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Transfer-Encoding: chunked
# Date: Wed, 05 Sep 2018 20:55:05 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
#   ],
#   "code": 499
# }
##
#
# Log settings retrieval - authenticated
# !! IMPORTANT: the logDir param always has a trailing slash, regardless of
# what was set.  The arcgis_site type will force a trailing slash.
##
# [james@arcgis ~]$ curl -XGET -is http://localhost:6080/arcgis/admin/logs/settings?f=json&token=...
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Transfer-Encoding: chunked
# Date: Wed, 05 Sep 2018 20:55:07 GMT
# Server:
#
# {
#   "settings": {
#     "logDir": "/opt/arcgis/data/server/logs/",
#     "logLevel": "INFO",
#     "maxErrorReportsCount": 10,
#     "maxLogFileAge": 90,
#     "usageMeteringEnabled": false,
#     "statisticsConfig": {
#       "enabled": true,
#       "samplingInterval": 30,
#       "maxHistory": 0,
#       "statisticsDir": "/opt/arcgis/server/usr/directories/arcgissystem"
#     }
#   }
# }
##
#
# Log settings update - authenticated
##
# [james@arcgis ~]$ curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -is -d \
# 'logDir=/opt/arcgis/data/server/logs-moved&logLevel=WARNING&maxLogFileAge=90&maxErrorReportsCount=10' \
# 'http://localhost:6080/arcgis/admin/logs/settings/edit?f=json&token=...'
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 314
# Date: Thu, 06 Sep 2018 01:48:25 GMT
# Server:
#
# {
#   "status": "success",
#   "settings": {
#     "logDir": "/opt/arcgis/data/server/logs-moved/",
#     "logLevel": "WARNING",
#     "maxErrorReportsCount": 10,
#     "maxLogFileAge": 90,
#     "usageMeteringEnabled": false,
#     "statisticsConfig": {
#       "enabled": true,
#       "samplingInterval": 30,
#       "maxHistory": 0,
#       "statisticsDir": "/opt/arcgis/server/usr/directories/arcgissystem"
#     }
#   }
# }
##
#
# Log settings update -unauthenticated
##
# [james@arcgis ~]$ curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -is -d \
# 'logDir=/opt/arcgis/data/server/logs-moved&logLevel=WARNING&maxLogFileAge=90&maxErrorReportsCount=10' \
# 'http://localhost:6080/arcgis/admin/logs/settings/edit?f=json'
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 144
# Date: Thu, 06 Sep 2018 02:00:04 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
#   ],
#   "code": 499
# }
##
#
# Config store retrieval - unauthenticated
##
# [james@arcgis ~]$ curl -XGET  -is http://localhost:6080/arcgis/admin/system/configstore?f=json
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Transfer-Encoding: chunked
# Date: Wed, 05 Sep 2018 21:00:32 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
#   ],
#   "code": 499
# }
##
#
# Config store retrieval - authenticated
##
# [james@arcgis ~]$ curl -XGET -is http://localhost:6080/arcgis/admin/system/configstore?f=json&token=gIYkoECDzoZr5zQrI_UP_eNN1LGk2xcsY6YZk7rpBafQKyEpUa55Inv1Wkb_HCTy
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Transfer-Encoding: chunked
# Date: Wed, 05 Sep 2018 21:00:41 GMT
# Server:
#
# {
#   "type": "FILESYSTEM",
#   "connectionString": "/opt/arcgis/data/server/config-store",
#   "localRepositoryPath": "/opt/arcgis/server/usr/local",
#   "status": "Ready"
# }
##
#
# Config store update - authenticated
##
# [james@arcgis ~]$ curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -is -d \
# 'type=FILESYSTEM&connectionString=/opt/arcgis/data/server/config-store-moved/&move=true&runAsync=false' \
# 'http://localhost:6080/arcgis/admin/system/configstore/edit?f=json&token=...'
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 20
# Date: Thu, 06 Sep 2018 01:57:15 GMT
# Server:
#
# {
#   "status": "success"
# }
##
#
# Config store update - unauthenticated
##
# [james@arcgis ~]$ curl -XPOST -H 'Content-Type: application/x-www-form-urlencoded' -is -d \
# 'type=FILESYSTEM&connectionString=/opt/arcgis/data/server/config-store-moved/&move=true&runAsync=false' \
# 'http://localhost:6080/arcgis/admin/system/configstore/edit?f=json'
# HTTP/1.1 200 OK
# Content-Type: text/plain;charset=UTF-8
# Content-Length: 144
# Date: Thu, 06 Sep 2018 01:58:13 GMT
# Server:
#
# {
#   "status": "error",
#   "messages": [
#     "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
#   ],
#   "code": 499
# }
##
#
# Bad token messages
##
# {
#   "status": "error",
#   "messages": [
#     "Token Expired."
#   ],
#   "code": 498
# }
##
# or
##
# {
#   "status": "error",
#   "messages": [
#     "Could not decrypt token. Token may not be valid."
#   ],
#   "code": 498
# }
##
#
# On initial system setup the site does not exist.
# TODO: figure out what the response to an API call to the base site is when there is no site
#
##
Puppet::Type.type(:arcgis_site).provide(
  :ruby,
  parent: Puppet::Provider::ArcGISRESTAPI,
  server_base_uri: 'http://localhost:6080/arcgis',
  http_read_timeout: 3600,
  admin_username: 'admin',
  admin_password: 'admin',
) do
  desc 'A REST API based provider to manage the ArcGIS Enterprise Site.'

  SINGLETON_NAME ||= 'arcgis'.freeze

  SITE_CREATE_ENDPOINT = '/admin/createNewSite'.freeze
  SITE_RETRIEVE_ENDPOINT = '/admin/'.freeze
  SITE_DELETE_ENDPOINT = '/admin/deleteSite'.freeze

  CONFIGSTORE_RETRIEVE_ENDPOINT = '/admin/system/configstore'.freeze
  CONFIGSTORE_UPDATE_ENDPOINT = '/admin/system/configstore/edit'.freeze

  LOGSETTINGS_RETRIEVE_ENDPOINT = '/admin/logs/settings'.freeze
  LOGSETTINGS_UPDATE_ENDPOINT = '/admin/logs/settings/edit'.freeze

  mk_resource_methods

  def do_flush
    # TODO: this doesn't seem to ever get hit
    if @property_flush[:ensure] == :absent
      rest_delete
      return
    end

    # TODO: is there some other way to differentiate between create and update?
    upstream = rest_retrieve
    if upstream.nil? || upstream.name != resource[:name]
      rest_create
    elsif resource[:ensure] == :absent
      rest_delete
    else
      rest_update
    end
  end

  # Use the current resource to generate a hash that is ready to be turned into
  # form data for create or update.
  def type_to_form_ready_hash_site
    {
      username:              resource[:username],
      password:              resource[:password],
      configStoreConnection: JSON.generate(type_to_form_ready_hash_configstore),
      settings:              JSON.generate(type_to_form_ready_hash_logsettings),
      runAsync:              false,
    }
  end

  # Use the current resource to generate a hash that is ready to be turned into
  # form data for create or update.
  def type_to_form_ready_hash_configstore
    {
      type:             resource[:configstoretype],
      connectionString: resource[:configdir],
      move:             true,
      runAsync:         false,
    }
  end

  # Use the current resource to generate a hash that is ready to be turned into
  # form data for create or update.
  #
  # Note: the documented format, which includes a settings level, does not work.
  def type_to_form_ready_hash_logsettings
    {
      # settings: {
      logDir:               resource[:logdir],
      logLevel:             resource[:serverloglevel],
      maxLogFileAge:        resource[:logmaxfileage],
      maxErrorReportsCount: resource[:logmaxerrorreports],
      # },
    }
  end

  def rest_create
    response = self.class.send_post(SITE_CREATE_ENDPOINT, type_to_form_ready_hash_site, nil)
    self.class.validate_response(response)
  end

  def rest_retrieve
    self.class.retrieve_instance(resource[:name])
  end

  def rest_update
    # FIXME: we probably want to be more intelligent here and only run the
    # updates for the endpoint that needs them...

    response = self.class.send_auth_post(CONFIGSTORE_UPDATE_ENDPOINT, type_to_form_ready_hash_configstore)
    self.class.validate_response(response)

    response = self.class.send_auth_post(LOGSETTINGS_UPDATE_ENDPOINT, type_to_form_ready_hash_logsettings)
    self.class.validate_response(response)
  end

  def rest_delete
    response = self.class.send_auth_post(SITE_DELETE_ENDPOINT, {})
    self.class.validate_response(response)
  end

  # Convert from the JSON objects that comes back from our rest call into a
  # site object
  def self.json_object_to_type(configstore, logsettings)
    type_hash = {
      ensure: :present,
      name:   SINGLETON_NAME,
    }

    unless logsettings.nil? || logsettings[:settings].nil?
      type_hash[:logdir] = logsettings[:settings][:logDir]
      type_hash[:serverloglevel] = logsettings[:settings][:logLevel]
      type_hash[:logmaxerrorreports] = logsettings[:settings][:maxErrorReportsCount]
      type_hash[:logmaxfileage] = logsettings[:settings][:maxLogFileAge]
    end

    unless configstore.nil?
      type_hash[:configdir] = configstore[:connectionString]
      type_hash[:configstoretype] = configstore[:type]
    end

    new(type_hash)
  end

  # There can only ever be one site, so name is optional
  def self.retrieve_instance(_site = nil)
    # Without authorization, the site endpoint will return JSON
    # with code=404 to indicate that the site does not exist,
    # or code=499 after to indicate that it exists but requires
    # authorization.
    test_response = send_get(SITE_RETRIEVE_ENDPOINT, nil)
    test_body = JSON.parse(test_response.body, symbolize_names: true)
    return nil if test_body.nil? || test_body[:code].to_i != 499

    # This doesn't return information that's useful here
    # site_response = send_auth_get(SITE_RETRIEVE_ENDPOINT)
    # site_body = JSON.parse(site_response.body, :symbolize_names => true)

    configstore_response = send_auth_get(CONFIGSTORE_RETRIEVE_ENDPOINT)
    configstore_body = JSON.parse(configstore_response.body, symbolize_names: true)

    logsettings_response = send_auth_get(LOGSETTINGS_RETRIEVE_ENDPOINT)
    logsettings_body = JSON.parse(logsettings_response.body, symbolize_names: true)

    json_object_to_type(configstore_body, logsettings_body)
  end

  # There can only ever be one site, so just wrap retrieve_instance
  def self.retrieve_instances
    instance = retrieve_instance(nil)
    return [] if instance.nil?
    [instance]
  end
end
