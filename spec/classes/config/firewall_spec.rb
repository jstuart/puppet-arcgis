require 'spec_helper'

describe 'arcgis::config::firewall' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end

  on_supported_os(
    hardwaremodels: ['x86_64'],
    supported_os: [
      {
        'operatingsystem' => 'RedHat',
        'operatingsystemrelease' => ['7'],
      },
    ],
  ).each do |_os, os_facts|
    # FIXME: remove after tests added
    # rubocop:disable RSpec/EmptyExampleGroup
    context 'defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end
      # TODO: tests
    end

    context 'non-defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end
      # TODO: tests
    end

    context 'disabled' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end
      # TODO: tests
    end
  end
end
