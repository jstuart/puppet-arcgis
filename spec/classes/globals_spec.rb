require 'spec_helper'

describe 'arcgis::globals' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end

    arcgis_supported_versions.each do |version|
      context "with supported version #{version}" do
        let(:facts) { os_facts }
        let(:params) { { version: version } }

        it { is_expected.to compile }
      end
    end

    context 'with unsupported version 10.3' do
      let(:facts) { os_facts }
      let(:params) { { version: '10.3' } }

      it { is_expected.to compile.and_raise_error(%r{Unsupported ArcGIS version: 10.3}) }
    end

    context 'with supported username' do
      let(:facts) { os_facts }
      let(:params) { { psa_username: 'my_user' } }

      it { is_expected.to compile }
    end

    context 'with unsupported username' do
      let(:facts) { os_facts }
      let(:params) { { psa_username: '' } }

      it { is_expected.to compile.and_raise_error(%r{The psa_username is required.}) }
    end

    context 'with supported password' do
      let(:facts) { os_facts }
      let(:params) { { psa_password: 'my_password' } }

      it { is_expected.to compile }
    end

    context 'with unsupported password' do
      let(:facts) { os_facts }
      let(:params) { { psa_password: '' } }

      it { is_expected.to compile.and_raise_error(%r{The psa_password is required.}) }
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
    context 'with bad password: true' do
      let(:facts) { os_facts }
      let(:params) { { run_as_user_password: true } }

      it { is_expected.to compile.and_raise_error(%r{password hash}) }
    end

    context 'with bad password: plaintext' do
      let(:facts) { os_facts }
      let(:params) { { run_as_user_password: 'mypassword' } }

      it { is_expected.to compile.and_raise_error(%r{password hash}) }
    end

    context 'with good password: sha256' do
      let(:facts) { os_facts }
      let(:params) { { run_as_user_password: '$5$U328Pps8u/SZVuEI$.jBw517WdJ/hGIGb1uxSdXO2rIkziLpINKiwd52qNM6' } }

      it { is_expected.to compile }
    end

    context 'with good password: sha512' do
      let(:facts) { os_facts }
      let(:params) { { run_as_user_password: '$6$BYSNiqlDi7WB8Dqi$raShU30lVKrWi5ZPPZiYtyqNTnSp81e5NBbTKRq3GHTtZnHWI4rZsh.IxFrhzKDMtg3LMlfVbfT6x3DvYKPvD0' } }

      it { is_expected.to compile }
    end
  end

  on_supported_os(
    hardwaremodels: ['x86_64'],
    supported_os: [
      {
        'operatingsystem' => 'RedHat',
        'operatingsystemrelease' => ['6'],
      },
    ],
  ).each do |_os, os_facts|
    context 'with providers' do
      context 'with supported systemd' do
        let(:facts) do
          os_facts.merge(service_provider: 'systemd')
        end
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
            }
          EOS
        end

        it { is_expected.to compile }
      end
      context 'with supported sysv' do
        let(:facts) do
          os_facts.merge(service_provider: 'redhat')
        end
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
            }
          EOS
        end

        it { is_expected.to compile }
      end

      context 'with unsupported init' do
        let(:facts) do
          os_facts.merge(service_provider: 'init')
        end
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
            }
          EOS
        end

        it { is_expected.to compile.and_raise_error(%r{This module only supports 'systemd' and 'redhat' service providers; 'init' is active on this system.}) }
      end
    end
  end
end
