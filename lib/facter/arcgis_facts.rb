
require 'facter'
require 'json'
require 'time'

# Encapsulation for ArcGIS facts
#
# TODO: it would probably be a good idea to make the collection of some of
# these facts optional to save cycles.
module ArcGISFacts
  REST_INFO_URI ||= 'http://localhost:6080/arcgis/rest/info?f=json'.freeze
  SITE_STATUS_URI ||= 'http://localhost:6080/arcgis/admin/?f=json'.freeze

  # Fact prefix
  @prefix = 'arcgis'.freeze
  @config = {}
  @esri_properties = {}
  @token = nil
  @token_expires = nil

  # Set host fact
  def self.set_fact(key, value)
    ::Facter.add("#{@prefix}_#{key}") do
      setcode { value }
    end
  end

  def self.collect_puppet_config(static_info_path)
    # Create a default config package and then flatten the real values over top
    # of it.
    config = {
      current_version:              '10.6.1',
      supported_versions:           ['10.6.1'],
      path_base:                    '/opt',
      path_arcgis:                  '/opt/arcgis',
      path_software:                '/opt/arcgis/software',
      path_software_archives:       '/opt/arcgis/software/archives',
      path_software_setup:          '/opt/arcgis/software/setup',
      path_software_license:        '/opt/arcgis/software/license',
      path_software_temp:           '/opt/arcgis/software/tmp',
      path_server_install:          '/opt/arcgis/server',
      path_web_adaptor_install:     '/opt/arcgis/webadaptor10.6.1',
      path_portal_install:          '/opt/arcgis/portal',
      path_data_store_install:      '/opt/arcgis/datastore',
      license_file:                 '/opt/arcgis/softwre/license/authorization.ecp',
      service_user:                 'arcgis',
      service_user_home:            '/home/arcgis',
      server_tools_dir:             '/opt/arcgis/server/tools',
      facter_enable_rest:           true,
      facter_enable_disk_facts:     true,
      facter_enable_esri_props:     true,
      facter_enable_detect_install: true,
      facter_enable_detect_patches: true,
    }

    if File.exist? static_info_path
      puppet_content = File.read(static_info_path)
      puppet_config = JSON.parse(puppet_content, symbolize_names: true)
      config.merge!(puppet_config)
    end

    @config = config
    # Store off the base config for access
    set_fact('facter_config', @config)
  end

  def self.collect_disk_facts
    return unless @config[:facter_enable_disk_facts]
    # Store disk space availability in /tmp
    # FIXME: these might be better off in the actual server manifest as we won't need to
    # actually run the commands unless the class is attached. Here they need to be moved
    # up outside of the info_file_exists check to be meaningful.
    #
    # FIXME: the actual ArcGIS installer probably uses the system default not a hardcoded /tmp
    set_fact('avail_mb_tmp', Facter::Core::Execution.exec('df -l --output=avail -BM /tmp | tail -n 1'))
    tmp_source = Facter::Core::Execution.execute('df -l --output=source /tmp | tail -n 1')
    unless tmp_source.empty?
      tmp_source_regex = %r{^\s*#{tmp_source}\s+}
      File.readlines('/etc/mtab').each do |line|
        next unless line.match(tmp_source_regex)
        set_fact('tmp_has_noexec', line.match(%r{noexec}))
      end
    end

    software_check_dir = (File.exist? @config[:path_software]) ? @config[:path_software] : @config[:path_arcgis]
    set_fact('avail_mb_software', Facter::Core::Execution.execute('df -l --output=avail -BM %s | tail -n 1' % software_check_dir))

    server_check_dir = (File.exist? @config[:path_server_install]) ? @config[:path_server_install] : @config[:path_arcgis]
    set_fact('avail_mb_tmp', Facter::Core::Execution.execute('df -l --output=avail -BM %s | tail -n 1' % server_check_dir))
  end

  def self.collect_esri_properties
    return unless @config[:facter_enable_esri_props]
    # TODO: add error handling
    server_properties_files = Dir.glob(File.join(@config[:service_user_home], '.ESRI.properties.*'))
    server_properties_hash = {}

    return if server_properties_files.empty?

    server_properties_files.sort!
    latest_server_properties_filename = server_properties_files[-1]

    comment_match = %r{^\s*\#}
    param_match = %r{^\s*(?<key>.+)\s*=\s*(?<value>.*)\s*}
    File.readlines(latest_server_properties_filename).each do |line|
      case line
      when comment_match
        next
      else
        m = line.match(param_match)
        if m[:key] && !m[:key].empty?
          server_properties_hash[m[:key].to_sym] = m[:value] || nil
        end
      end
    end

    @esri_properties = server_properties_hash
    set_fact('esri_server_properties', server_properties_hash) unless server_properties_hash.empty?
  end

  def self.collect_installed_products
    return unless @config[:facter_enable_detect_install]
    # If we have the esri_properties information, we can make deconflict
    # that information with the puppet passed properties to come up with the
    # best paths for each product.
    #
    # The Esri properties should contain something like this:
    #
    # Valid product names are :ArcGISGeoEvent, :ArcGISServer, :ArcGISPortal, :ArcGISDataStore
    # esri_properties["Z_#{product_name}_INSTALL_DIR".to_sym]

    if @esri_properties[:Z_ArcGISServer_INSTALL_DIR]
      set_fact('server_installed', File.exist?(@esri_properties[:Z_ArcGISServer_INSTALL_DIR]))
    else
      set_fact('server_installed', File.exist?(File.join(@config[:path_server_install], 'startserver.sh')))
    end

    if @esri_properties[:Z_ArcGISPortal_INSTALL_DIR]
      set_fact('portal_installed', File.exist?(@esri_properties[:Z_ArcGISPortal_INSTALL_DIR]))
    else
      set_fact('portal_installed', File.exist?(File.join(@config[:path_portal_install], 'startportal.sh')))
    end

    if @esri_properties[:Z_ArcGISDataStore_INSTALL_DIR]
      set_fact('data_store_installed', File.exist?(@esri_properties[:Z_ArcGISDataStore_INSTALL_DIR]))
    else
      set_fact('data_store_installed', File.exist?(File.join(@config[:path_data_store_install], 'startserver.sh')))
    end

    # TODO: is there an indicator for WebAdaptor?
  end

  def self.collect_installed_patches
    return unless @config[:facter_enable_detect_patches]

    patch_log_file = File.join(@config[:path_server_install], '.ESRI_S_PATCH_LOG')
    return unless File.exist? patch_log_file

    # FIXME: need to pull an example from a system that has patches installed
    # to validate this.
    start_match = %r{^\#start}
    end_match = %r{^\#end}
    param_match = %r{^\s*(?<key>.+)\s*:\s*(?<value>.*)\s*}

    patch_list = []
    current_object = {}
    File.readlines(latest_server_properties_filename).each do |line|
      case line
      when start_match
        # FIXME: do we really want to just clear the object, because if it's not
        # already empty it might not have installed correctly?
        if current_object.empty?
          Facter.debug 'found arcgis patch start entry without a prior end; ' \
            "previous object: #{current_object}"
        end
      when end_match
        next if current_object.empty?
        patch_list << current_object
        current_object = {}
      else
        m = line.match(param_match)
        if m[:key] && !m[:key].empty?
          current_object[m[:key].to_sym] = m[:value] || nil
        end
      end
    end

    set_fact('installed_patches', current_objects)
    set_fact('installed_qfe_ids', current_objects.map { |p| p[:QFE_ID] || nil }.compact.uniq)
  end

  def self.token_expired?
    # If the token is set, the expiration is set, and the expiration timestamp
    # is in the future, the token is not expired.
    return false if @token && @token_expires && @token_expires.to_i > Time.now.to_i
    # Otherwise it is.
    true
  end

  def self.get_token(force = false)
    # allow the token to be cached unless we force regeneration
    return unless token_expired? || force
    # If we can get a server token we have lots of options for info
    token_tool = File.join(@config[:path_server_install], 'tools', 'generateadmintoken', 'generate-admin-token.sh')
    return unless File.exist?(token_tool)

    # Get a token that is valid for 2 minutes, which should be long enough to
    # check everything. If it's not long enough, something is not going well.
    raw_token = Facter::Core::Execution.execute('%s -e 2' % token_tool)
    return if raw_token.empty?

    token_output = JSON.parse(raw_token, symbolize_names: true)
    @token = token_output[:token] || nil
    @token_expires = token_output[:expires].to_i || nil
  end

  # Make an HTTP request
  def self.send_http_request(request, uri)
    http = Net::HTTP.new(uri.host, uri.port)
    # Short timeout for facts
    http.read_timeout = 60

    if uri.scheme == 'https'
      http.use_ssl = true
      # FIXME: how about something sane for cert verification?
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end

    Facter.debug("Request: #{request.method} #{uri.scheme}://#{uri.host}:#{uri.port}#{request.path}")
    Facter.debug(request.body) unless request.body.nil? || request.body.include?('password')

    http.request(request)
  end

  # Make an ArcGIS API call; GET only
  def self.do_api_call(request, uri)
    # First attempt
    response = send_http_request(request, uri)

    # If we're redirected, e.g. to HTTPS, make another attempt
    if response.code.to_i == 301
      # TODO: validate that the location header passes get params through
      location = response.header['location']
      Facter.debug("Moved to: #{location}")

      uri = URI.parse(location)
      request = Net::HTTP::Get.new(
        uri.request_uri,
      )
      # I don't see why this would be necessary unless it's being used for token auth
      # request.add_field('Referer', 'referer')

      # We're only doing one redirect, so whatever is returned here is going back
      response = send_http_request(request, uri)
    end

    Facter.debug("Response: #{response.code} #{response.body}")
    response
  end

  def self.collect_rest_info
    uri = URI.parse(REST_INFO_URI)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = do_api_call(request, uri)
    return unless response.code.to_i == 200

    @rest_info = JSON.parse(response.body, symbolize_names: true)
    set_fact('rest_info', @rest_info)
  end

  def self.collect_has_site
    uri = URI.parse(SITE_STATUS_URI)
    request = Net::HTTP::Get.new(uri.request_uri)

    response = do_api_call(request, uri)
    body = JSON.parse(response.body, symbolize_names: true)
    # Without authorization, the site endpoint will return JSON
    # with code=404 to indicate that the site does not exist,
    # or code=499 after to indicate that it exists but requires
    # authorization.
    set_fact('site_exists', (body && body[:code].to_i == 499))
  end

  # Collect information and set facts
  def self.run
    static_info_dir = '/etc/arcgis'
    static_info_filename = 'puppet_data.json'
    static_info_path = File.join(static_info_dir, static_info_filename)

    # If the static directory doesn't exist, bail here so we don't waste
    # more cycles.
    info_file_exists = File.exist? static_info_path
    set_fact('puppet_init_done', info_file_exists)
    return unless info_file_exists

    # Grab the stuff we can off of the filesystem
    collect_puppet_config(static_info_path)
    collect_disk_facts
    collect_esri_properties
    collect_installed_products
    collect_installed_patches

    return unless @config[:facter_enable_rest]
    # Then run some queries
    # get_token
    collect_rest_info
    collect_has_site
  end
end

ArcGISFacts.run
