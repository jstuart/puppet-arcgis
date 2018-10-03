require 'spec_helper'

describe 'arcgis::tools::epel' do
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
        'operatingsystemrelease' => ['7', '6'],
      },
    ],
  ).each do |_os, os_facts|
    let(:facts) do
      os_facts
    end

    context 'will work with default globals' do
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will not contain epel class' do
        it { is_expected.not_to contain_class('epel') }
      end
    end

    context 'will work with non-default globals' do
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_epel => true,
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will contain epel class' do
        it { is_expected.to contain_class('epel') }
      end
    end
  end
end
