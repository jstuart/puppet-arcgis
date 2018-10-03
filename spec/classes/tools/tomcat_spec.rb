require 'spec_helper'

describe 'arcgis::tools::tomcat' do
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

      context 'will not contain tomcat class' do
        it { is_expected.not_to contain_class('tomcat') }
      end
    end

    context 'will work with non-default globals and all dependencies' do
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_epel   => true,
            manage_java   => true,
            manage_tomcat => true,
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will contain tomcat class' do
        it { is_expected.to contain_class('tomcat') }
      end

      context 'will contain tomcat instance' do
        it {
          is_expected.to contain_tomcat__instance('arcgis').with(
            install_from_source: false,
            package_name:        'tomcat',
          )
        }

        it { is_expected.to contain_tomcat__instance('arcgis').that_requires('Class[arcgis::tools::epel]') }
        it { is_expected.to contain_tomcat__instance('arcgis').that_requires('Class[arcgis::tools::java]') }
      end

      context 'will contain tomcat service' do
        it {
          is_expected.to contain_tomcat__service('arcgis').with(
            use_jsvc:     false,
            use_init:     true,
            service_name: 'tomcat',
          )
        }

        it { is_expected.to contain_tomcat__service('arcgis').that_requires('Tomcat::Instance[arcgis]') }
        it { is_expected.to contain_tomcat__service('arcgis').that_subscribes_to('Tomcat::Instance[arcgis]') }
      end
    end

    context 'will work with non-default globals without dependencies' do
      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            manage_epel   => false,
            manage_java   => false,
            manage_tomcat => true,
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will contain tomcat class' do
        it { is_expected.to contain_class('tomcat') }
      end

      context 'will contain tomcat instance' do
        it {
          is_expected.to contain_tomcat__instance('arcgis').with(
            install_from_source: false,
            package_name:        'tomcat',
          )
        }

        it { is_expected.to contain_tomcat__instance('arcgis').that_requires('Class[arcgis::tools::epel]') }
        it { is_expected.to contain_tomcat__instance('arcgis').that_requires('Class[arcgis::tools::java]') }
      end

      context 'will contain tomcat service' do
        it {
          is_expected.to contain_tomcat__service('arcgis').with(
            use_jsvc:     false,
            use_init:     true,
            service_name: 'tomcat',
          )
        }

        it { is_expected.to contain_tomcat__service('arcgis').that_requires('Tomcat::Instance[arcgis]') }
        it { is_expected.to contain_tomcat__service('arcgis').that_subscribes_to('Tomcat::Instance[arcgis]') }
      end
    end
  end
end
