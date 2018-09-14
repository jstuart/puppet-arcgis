
require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
#require 'pry'

begin
  require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))
rescue LoadError => loaderror
  warn "Could not require spec_helper_local: #{loaderror.message}"
end

include RspecPuppetFacts

def fixture_path
  File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures'))
end

def arcgis_supported_versions
  [
    '10.4',
    '10.4.1',
    '10.5',
    '10.5.1',
    '10.6',
    '10.6.1',
  ]
end

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

# default_facts_path = File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml'))
# default_module_facts_path = File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml'))
default_facts_path = File.expand_path(File.join(fixture_path, 'facts', 'default_facts.yml'))
default_module_facts_path = File.expand_path(File.join(fixture_path, 'facts', 'default_module_facts.yml'))

if File.exist?(default_facts_path) && File.readable?(default_facts_path)
  default_facts.merge!(YAML.safe_load(File.read(default_facts_path)))
end

if File.exist?(default_module_facts_path) && File.readable?(default_module_facts_path)
  default_facts.merge!(YAML.safe_load(File.read(default_module_facts_path)))
end

add_custom_fact(:service_provider, 'systemd')

RSpec.configure do |c|
  c.add_setting :fixture_path, default: fixture_path
  c.mock_with(:rspec)
  c.hiera_config = File.join(fixture_path, '/hiera/hiera.yaml')
  c.default_facts = default_facts
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
  end
  # c.after(:suite) do
  #   RSpec::Puppet::Coverage.report!(100)
  # end
end

def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module)
    last_module.const_get(next_module)
  end
end

# 'spec_overrides' from sync.yml will appear below this line
