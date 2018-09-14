$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..'))

require 'puppet_x/arcgis/arcgis_rest_resource'

Puppet::Type.newtype(:arcgis_directory) do
  extend ArcGISRESTResource

  # DIRECTORY_TYPES = ['CACHE', 'JOBREGISTRY', 'JOBS', 'INDEX', 'INPUT', 'KML', 'OUTPUT', 'SYSTEM', 'UPLOADS']
  # From: https://developers.arcgis.com/rest/enterprise-administration/server/editdirectory.htm
  # You cannot edit the properties of UPLOADS, KML, INDEX, JOBREGISTRY, and INPUT directory types.
  # These types are maintained internally by the server under the umbrella of the SYSTEM directory type.
  DIRECTORY_TYPES = ['CACHE', 'JOBS', 'OUTPUT', 'SYSTEM'].freeze
  CLEANUP_MODES = ['NONE', 'TIME_ELAPSED_SINCE_LAST_MODIFIED'].freeze

  def default_cleanupmode
    case self[:directorytype]
    when :JOBS
      'TIME_ELAPSED_SINCE_LAST_MODIFIED'
    when :OUTPUT
      'TIME_ELAPSED_SINCE_LAST_MODIFIED'
    when :SYSTEM
      'TIME_ELAPSED_SINCE_LAST_MODIFIED'
    # See comment for DIRECTORY_TYPES
    # when 'UPLOADS'
    #   'TIME_ELAPSED_SINCE_LAST_MODIFIED'
    else
      'NONE'
    end
  end

  def default_maxfileage
    case self[:directorytype]
    when :JOBS
      360
    when :OUTPUT
      10
    when :SYSTEM
      1440
    # See comment for DIRECTORY_TYPES
    # when :UPLOADS
    #   1440
    else
      0
    end
  end

  desc 'Manages the ArcGIS Enterprise Site.'

  ensurable

  newparam(:name) do
    desc 'The name of the directory resource.'

    isnamevar
  end

  newproperty(:physicalpath) do
    desc 'The absolute physical path of the server directory.'
    newvalues(%r{^\/.*$})

    isrequired
  end

  newproperty(:directorytype) do
    desc 'The type of server directory.'
    newvalues(:CACHE, :JOBS, :OUTPUT, :SYSTEM)

    isrequired
  end

  newproperty(:cleanupmode) do
    desc 'Defines if files in the server directory needs to be cleaned up.'

    munge do |value|
      if value.nil?
        default_cleanupmode
      elsif CLEANUP_MODES.include?(value)
        value
      else
        raise Puppet::Error, "Invalid value: #{value}; valid values are #{CLEANUP_MODES}" unless CLEANUP_MODES.include?(value)
      end
    end
  end

  newproperty(:maxfileage) do
    desc 'Defines how long a file in the directory needs to be kept (in days) before it is deleted.'

    munge do |value|
      if value.nil?
        default_maxfileage
      elsif value.is_a? Integer
        value
      elsif %r{^\d+$}.match?(value.to_s)
        value.to_i
      else
        raise Puppet::Error, 'Invalid value: integer expected' unless value.is_a? Integer
      end
    end
  end

  newproperty(:description) do
    desc 'An optional description for the server directory.'
  end

  validate do
    raise ArgumentError, 'physicalpath is required.' if self[:physicalpath].nil?
    raise ArgumentError, 'directorytype is required.' if self[:directorytype].nil?

    # Use type specific defaults for cleanup mode
    if self[:cleanupmode].nil?
      self[:cleanupmode] = default_cleanupmode
    end

    # Use type specific defaults for max file age
    if self[:maxfileage].nil?
      self[:maxfileage] = default_maxfileage
    end
  end
end
