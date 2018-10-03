require 'spec_helper'

describe 'arcgis::tools::java' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          java_major_version: '8',
          java_patch_level: '181',
        )
      end

      it { is_expected.to compile }
    end
  end

  context 'with java 8' do
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
        os_facts.merge(
          java_major_version: '8',
          java_patch_level: '181',
        )
      end

      context "with RHEL #{os_facts[:operatingsystemrelease]}" do

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

          context 'will not contain java class' do
            it { is_expected.not_to contain_class('java') }
          end
        end

        context 'will work with non-default globals' do
          let(:pre_condition) do
            <<-EOS
              class { 'arcgis::globals':
                manage_java => true,
              }
            EOS
          end

          context 'will compile with globals' do
            it { is_expected.to compile }
          end

          context 'will contain java class' do
            it {
              is_expected.to contain_class('java').with(
                distribution: 'jre',
                version: '1.8.0.181',
              )
            }
          end
        end
      end
    end
  end

  context 'without java version' do
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
        os_facts.merge(
          java_major_version: nil,
          java_patch_level: nil,
        )
      end
      context "with RHEL #{os_facts[:operatingsystemrelease]}" do

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

          context 'will not contain java class' do
            it { is_expected.not_to contain_class('java') }
          end
        end

        context 'will work with non-default globals' do
          let(:pre_condition) do
            <<-EOS
              class { 'arcgis::globals':
                manage_java => true,
              }
            EOS
          end

          context 'will compile with globals' do
            it { is_expected.to compile }
          end

          context 'will contain java class' do
            it {
              is_expected.to contain_class('java').with(
                distribution: 'jre',
                version: 'latest',
              )
            }
          end
        end
      end
    end
  end
end
