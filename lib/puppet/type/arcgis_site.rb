$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..'))

require 'puppet_x/arcgis/arcgis_rest_resource'

# FIXME: This could include directory settings that are duplicative
# with arcgis_directory, however I could not get the create site
# API to work when passing directories and it would probably just
# be confusing to have that construct managed from both that type
# and this one.
Puppet::Type.newtype(:arcgis_site) do
  extend ArcGISRESTResource

  SINGLETON_NAME ||= 'arcgis'.freeze

  desc 'Manages the ArcGIS Enterprise Site.'

  ensurable

  newparam(:name) do
    desc 'The name of the site resource.'

    munge do |value|
      if value != SINGLETON_NAME
        Puppet.info("The arcgis_site is a singleton which should be named '#{SINGLETON_NAME}'; changing the passed name of '#{value}' to that.")
      end
      SINGLETON_NAME
    end

    isnamevar
  end

  newproperty(:configdir) do
    desc 'A file path or connection URL to the physical location of the store.'
    newvalues(%r{^\/.*$})

    isrequired
  end

  newproperty(:configstoretype) do
    desc 'Type of the configuration store. The default is FILESYSTEM.'
    newvalues(:FILESYSTEM)

    defaultto :FILESYSTEM
  end

  newproperty(:logdir) do
    desc 'File path to the root of the log directories.'

    # The API will always return a location with a trailing slash
    # so force it here to ensure we're comparing apples to apples.
    munge do |value|
      raise Puppet::Error, 'Invalid value for :logdir. The value must be an absolute path.' if value.nil? || value.empty?
      raise Puppet::Error, 'Invalid value for :logdir. The value must be an absolute path.' unless value.is_a? String
      raise Puppet::Error, "Invalid value \"#{value}\". The value must be an absolute path." unless value.start_with?('/')
      return value if value.end_with?('/')
      return value + '/'
    end

    defaultto '/var/log/arcgis/'
  end

  newproperty(:serverloglevel) do
    desc 'Can be one of [OFF, SEVERE, WARNING, INFO, FINE, VERBOSE, DEBUG].'
    newvalues(:OFF, :SEVERE, :WARNING, :INFO, :FINE, :VERBOSE, :DEBUG)

    defaultto(:WARNING)
  end

  newproperty(:logmaxerrorreports) do
    desc 'The maximum number of error report files per machine.'

    munge do |value|
      if value.nil?
        10
      elsif value.is_a? Integer
        value
      elsif %r{^\d+$}.match?(value.to_s)
        value.to_i
      else
        raise Puppet::Error, 'Invalid value: integer expected' unless value.is_a? Integer
      end
    end

    defaultto 10
  end

  newproperty(:logmaxfileage) do
    desc 'Represents the number of days that server should save a log file.'

    munge do |value|
      if value.nil?
        90
      elsif value.is_a? Integer
        value
      elsif %r{^\d+$}.match?(value.to_s)
        value.to_i
      else
        raise Puppet::Error, 'Invalid value: integer expected' unless value.is_a? Integer
      end
    end

    defaultto 90
  end

  validate do
    raise ArgumentError, 'configdir is required.' if self[:configdir].nil?
  end
end
