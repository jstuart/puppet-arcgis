require 'spec_helper'

describe 'arcgis::security::limits' do
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

      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf') }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis hard nofile 65536$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis soft nofile 65536$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis hard nproc 25059$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis soft nproc 25059$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis hard memlock unlimited$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis soft memlock unlimited$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis hard fsize unlimited$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis soft fsize unlimited$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis hard as unlimited$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^arcgis soft as unlimited$}) }
    end

    context 'non-defaults' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            run_as_user          => 'test',
            ulimits_nofile_hard  => 'test_1',
            ulimits_nofile_soft  => 'test_2',
            ulimits_nproc_hard   => 'test_3',
            ulimits_nproc_soft   => 'test_4',
            ulimits_memlock_hard => 1,
            ulimits_memlock_soft => 2,
            ulimits_fsize_hard   => 3,
            ulimits_fsize_soft   => 4,
            ulimits_as_hard      => 5,
            ulimits_as_soft      => 6,
          }
        EOS
      end

      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf') }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test hard nofile test_1$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test soft nofile test_2$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test hard nproc test_3$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test soft nproc test_4$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test hard memlock 1$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test soft memlock 2$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test hard fsize 3$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test soft fsize 4$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test hard as 5$}) }
      it { is_expected.to contain_file('/etc/security/limits.d/80-arcgis.conf').with_content(%r{^test soft as 6$}) }
    end

    context 'disabled' do
      let(:facts) { os_facts }
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_ulimits => false,
          }
        EOS
      end

      it { is_expected.not_to contain_file('/etc/security/limits.d/80-arcgis.conf') }
    end
  end
end
