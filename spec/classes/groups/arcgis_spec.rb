require 'spec_helper'

describe 'arcgis::groups::arcgis' do
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
    context 'defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end

      it { is_expected.to compile }
      it { is_expected.to contain_group('arcgis').with_gid(nil) }
    end

    context 'non-defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            run_as_user_group => 'esri',
            run_as_user_gid   => 876,
          }
        EOS
      end

      it { is_expected.to compile }
      it { is_expected.to contain_group('esri').with_gid(876) }
    end

    context 'disabled' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_run_as_user_group => false,
          }
        EOS
      end

      it { is_expected.to compile }
      it { is_expected.not_to contain_group('esri') }
    end
  end
end
