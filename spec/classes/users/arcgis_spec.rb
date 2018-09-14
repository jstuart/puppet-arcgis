require 'spec_helper'

describe 'arcgis::users::arcgis' do
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
      it { is_expected.to contain_user('arcgis').with_uid(nil) }
      it { is_expected.to contain_user('arcgis').with_gid('arcgis') }
      it { is_expected.to contain_user('arcgis').with_password(false) }
      it { is_expected.to contain_user('arcgis').with_managehome(true) }
      it { is_expected.to contain_user('arcgis').with_home('/home/arcgis') }
      it { is_expected.to contain_user('arcgis').with_shell('/bin/bash') }
    end

    context 'non-defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            # Service user
            run_as_user       => 'esri',
            run_as_user_group => 'gis',

            # Management of the service user
            run_as_user_password    => '$6$BYSNiqlDi7WB8Dqi$raShU30lVKrWi5ZPPZiYtyqNTnSp81e5NBbTKRq3GHTtZnHWI4rZsh.IxFrhzKDMtg3LMlfVbfT6x3DvYKPvD0',
            run_as_user_manage_home => false,
            run_as_user_home        => '/home/esri',
            run_as_user_shell       => '/bin/false',
            run_as_user_uid         => 876,

            # Management of the service user group
            manage_run_as_user_group => false,
          }
        EOS
      end

      it { is_expected.to compile }
      it { is_expected.to contain_user('esri').with_uid(876) }
      it { is_expected.to contain_user('esri').with_gid('gis') }
      it { is_expected.to contain_user('esri').with_password('$6$BYSNiqlDi7WB8Dqi$raShU30lVKrWi5ZPPZiYtyqNTnSp81e5NBbTKRq3GHTtZnHWI4rZsh.IxFrhzKDMtg3LMlfVbfT6x3DvYKPvD0') }
      it { is_expected.to contain_user('esri').with_managehome(false) }
      it { is_expected.to contain_user('esri').with_home('/home/esri') }
      it { is_expected.to contain_user('esri').with_shell('/bin/false') }
    end

    context 'disabled' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_run_as_user => false,
          }
        EOS
      end

      it { is_expected.to compile }
      it { is_expected.not_to contain_user('arcgis') }
    end
  end
end
