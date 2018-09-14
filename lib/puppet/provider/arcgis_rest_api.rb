$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..'))

require 'json'
require 'net/http'
require 'openssl'

# require 'puppet/provider/arcgis_rest'

# Parent class encapsulating general-use functions for children REST-based
# providers.
#
# This is a heavily modified copy of ElasticRest from elastic-elasticsearch
#
# Call to rest info endpoint with site installed
##
# [james@arcgis ~]$ curl -is http://localhost:6080/arcgis/rest/info?f=json
# HTTP/1.1 200 OK
# Vary: Origin
# Content-Type: text/plain;charset=utf-8
# Transfer-Encoding: chunked
# Date: Tue, 11 Sep 2018 01:35:59 GMT
# Server:
#
# {
#   "currentVersion": 10.51,
#   "fullVersion": "10.5.1",
#   "soapUrl": "http://localhost:6080/arcgis/services",
#   "secureSoapUrl": "https://localhost:6443/arcgis/services",
#   "authInfo": {
#     "isTokenBasedSecurity": true,
#     "tokenServicesUrl": "https://localhost:6443/arcgis/tokens/",
#     "shortLivedTokenValidity": 60
#   }
# }
##
#
class Puppet::Provider::ArcGISRESTAPI < Puppet::Provider
  DEFAULT_HTTP_READ_TIMEOUT = 3600
  SITE_GET_ENDPOINT = '/admin'.freeze
  SITE_CREATE_ENDPOINT = '/admin/createNewSite'.freeze
  TOKEN_CREATE_ENDPOINT = '/admin/generateToken'.freeze

  class << self
    attr_accessor :server_base_uri
    attr_accessor :http_read_timeout
    attr_accessor :admin_username
    attr_accessor :admin_password
    attr_accessor :token
  end

  # Store off the properties that need updating for this specific named object
  # in an instance variable so we can make a single call to the appropriate API.
  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  # If we're creating a new object set `:ensure` to `:present` so it gets handled
  # appropriately in `flush()`
  def create
    @property_flush[:ensure] = :present
  end

  # If we're checking to see if an object exists, just see if there is a
  # property named ensure in our current hash. If not, it doesn't exist.
  def exists?
    @property_hash[:ensure] == :present
  end

  # If we're deleting an existing  object set `:ensure` to `:absent` so it gets
  # handled appropriately in `flush()`
  def destroy
    @property_flush[:ensure] = :absent
  end

  def flush
    do_flush

    # Refresh the current properties for this instance
    @property_hash = self.class.retrieve_instance(resource[:name])
  end

  # All providers to override the logic needed to get an individual object,
  # usually to refresh the current settings.
  # def self.retrieve_instance
  #   nil
  # end

  # Allow providers to override the logic needed to get a list of all of the
  # instances.
  # def self.retrieve_instances
  #   []
  # end

  # Implement self.instances in a way that allows future control over the
  # specific method but defers the logic to the actual type providers.
  # See: http://garylarizza.com/blog/2013/12/15/seriously-what-is-this-provider-doing/
  def self.instances
    retrieve_instances
  end

  # Leverage self.instances to implement self.prefetch.
  # See: http://garylarizza.com/blog/2013/12/15/seriously-what-is-this-provider-doing/
  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def self.generate_admin_token
    # If the site does not exist, this is the output
    ##
    # [james@arcgis ~]$ curl -XPOST -H "Content-Type: application/x-www-form-urlencoded" -i -d 'username=...&password=...&client=requestip&expiration=30' http://localhost:6080/arcgis/admin/generateToken?f=json
    # HTTP/1.1 200 OK
    # Content-Type: text/plain;charset=UTF-8
    # Content-Length: 167
    # Date: Thu, 30 Aug 2018 20:22:55 GMT
    # Server:
    #
    # {"status":"error","messages":["Local machine 'ARCGIS.INTERNAL.LOCAL' is not participating in any Site. Please create a new Site or join an existing Site."],"code":500}
    ##
    #
    # If the site does exist, this is the output:
    ##
    # [james@arcgis ~]$ curl -XPOST -H "Content-Type: application/x-www-form-urlencoded" -i -d 'username=...&password=...&client=requestip&expiration=30' http://localhost:6080/arcgis/admin/generateToken?f=json
    # HTTP/1.1 200 OK
    # Content-Type: text/plain;charset=UTF-8
    # Content-Length: 102
    # Date: Thu, 30 Aug 2018 20:13:51 GMT
    # Server:
    #
    # {"token":"...","expires":"1535661831380"}
    ##

    request_data = {
      'username'   => @admin_username,
      'password'   => @admin_password,
      'client'     => 'requestip',
      'expiration' => 5, # minutes
    }

    Puppet.debug('username=' + request_data['username'])
    Puppet.debug('client=' + request_data['client'])
    Puppet.debug('expiration=' + request_data['expiration'].to_s)

    response = send_post(TOKEN_CREATE_ENDPOINT, request_data, nil)

    # response = send_request(request, uri)
    validate_response(response)

    raise Puppet::Error, "Failed to generate token, HTTP code: #{response.code}; HTTP response: #{response.body}" unless response.code.to_i == 200
    JSON.parse(response.body)['token']

    # install_dir = '/opt/arcgis/server'
    #
    # generate_admin_token_cmd = [
    #   ::File.join(install_dir, 'tools','generateadmintoken','generate-admin-token.sh'),
    #   '-e', expiration.to_s].join(' ')
    #
    # cmd = Mixlib::ShellOut.new(generate_admin_token_cmd,
    #       { :user => node['arcgis']['run_as_user'],
    #         :timeout => 1800 })
    # cmd.run_command
    # cmd.error!
    #
    # JSON.parse(cmd.stdout)['token']
  end

  # Get a token, fetching one if needed. Note that we don't care about
  # synchronization here because we can grab as many tokens as we want.
  def self.cached_token
    if @token.nil?
      @token = generate_admin_token
    end
    @token
  end

  # Post data and return the results, making sure to request JSON
  def self.send_post(endpoint, form_hash, token)
    uri = URI.parse(@server_base_uri + endpoint)

    query_param_array = URI.decode_www_form(uri.query || '')
    # make sure we get JSON back
    query_param_array << ['f', 'json']
    # if we have a token, pass it too
    unless token.nil?
      query_param_array << ['token', token]
    end
    uri.query = URI.encode_www_form(query_param_array)

    request = Net::HTTP::Post.new(uri.request_uri)

    request.set_form_data(form_hash)

    send_request(request, uri)
  end

  # Get data and return the results, making sure to request JSON
  def self.send_get(endpoint, token)
    uri = URI.parse(@server_base_uri + endpoint)

    query_param_array = URI.decode_www_form(uri.query || '')
    # make sure we get JSON back
    query_param_array << ['f', 'json']
    # if we have a token, pass it too
    unless token.nil?
      query_param_array << ['token', token]
    end
    uri.query = URI.encode_www_form(query_param_array)

    request = Net::HTTP::Get.new(uri.request_uri)

    send_request(request, uri)
  end

  # Grab the current token and pass it along to use for auth
  def self.send_auth_post(endpoint, form_hash)
    send_post(endpoint, form_hash, cached_token)
  end

  # Grab the current token and pass it along to use for auth
  def self.send_auth_get(endpoint)
    send_get(endpoint, cached_token)
  end

  ##########################################################
  # Some of this comes from cookbooks/arcgis-enterprise/libraries/server_admin_client.rb
  ##########################################################

  # Request routine from Chef module
  def self.send_request(request, uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = @http_read_timeout || 3600

    if uri.scheme == 'https'
      http.use_ssl = true
      # FIXME: how about something sane for cert verification?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    Puppet.debug("Request: #{request.method} #{uri.scheme}://#{uri.host}:#{uri.port}#{request.path}")
    Puppet.debug(request.body) unless request.body.nil? || request.body.include?('password')

    response = http.request(request)

    if response.code.to_i == 301
      Puppet.debug("Moved to: #{response.header['location']}")

      uri = URI.parse(response.header['location'])

      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = 3600

      if uri.scheme == 'https'
        http.use_ssl = true
        # FIXME: how about something sane for cert verification?
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      if request.method == 'POST'
        body = request.body
        request = Net::HTTP::Post.new(
          URI.parse(response.header['location']).request_uri,
        )
        request.body = body
      else
        request = Net::HTTP::Get.new(
          URI.parse(response.header['location']).request_uri,
        )
      end

      request.add_field('Referer', 'referer')

      response = http.request(request)
    end

    Puppet.debug("Response: #{response.code} #{response.body}")
    response
  end

  # Return validation from the Chef module
  def self.validate_response(response)
    raise Puppet::Error, 'Moved permanently to ' + response.header['location'] if response.code.to_i == 301
    raise Puppet::Error, response.message if response.code.to_i > 300
    return unless response.code.to_i == 200
    error_info = JSON.parse(response.body)
    raise Puppet::Error, error_info['messages'].join(' ') if error_info['status'] == 'error'
  end
end
