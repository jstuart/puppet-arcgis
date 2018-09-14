require 'spec_helper'

describe 'arcgis::common' do
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
    context 'directories' do
      context 'defaults' do
        let(:facts) { os_facts }
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
            }
          EOS
        end

        context 'check compile with globals' do
          it { is_expected.to compile }
        end

        context 'check static info' do
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').that_requires('File[/etc/arcgis]') }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"current_version": "10.6.1"}) }
          # TODO: supported_versions
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_base": "/opt"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_arcgis": "/opt/arcgis"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software": "/opt/arcgis/software"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_archives": "/opt/arcgis/software/archives"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_setup": "/opt/arcgis/software/setup"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_license": "/opt/arcgis/software/license"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_temp": "/opt/arcgis/software/tmp"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_server_install": "/opt/arcgis/server"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_web_adaptor_install": "/opt/arcgis/webadaptor10.6.1"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_portal_install": "/opt/arcgis/portal"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_data_store_install": "/opt/arcgis/datastore"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"license_file": "/opt/arcgis/software/license/authorization.ecp"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"service_user": "arcgis"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"service_user_home": "/home/arcgis"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"server_tools_dir": "/opt/arcgis/server/tools"}) }
        end

        context 'check base dirs' do
          # Make sure arcgis group can write to the arcgis folder or installs will fail
          it { is_expected.to contain_file('/opt/arcgis').with_owner('root') }
          it { is_expected.to contain_file('/opt/arcgis').with_group('arcgis') }
          it { is_expected.to contain_file('/opt/arcgis').with_mode('0775') }
          it { is_expected.to contain_file('/opt/arcgis/software') }
          it { is_expected.to contain_file('/opt/arcgis/software/archives') }
          it { is_expected.to contain_file('/opt/arcgis/software/archives/10.6.1') }
          it { is_expected.to contain_file('/opt/arcgis/software/setup') }
          it { is_expected.to contain_file('/opt/arcgis/software/setup/10.6.1') }
          it { is_expected.to contain_file('/opt/arcgis/software/license') }
          it { is_expected.to contain_file('/opt/arcgis/software/tmp') }
          it { is_expected.to contain_file('/opt/arcgis/software/tmp').with_owner('arcgis') }
          it { is_expected.to contain_file('/opt/arcgis/software/tmp').with_group('arcgis') }
          it { is_expected.to contain_file('/opt/arcgis/software/tmp').with_mode('1770') }
          it { is_expected.to contain_archive('/opt/arcgis/software/license/authorization.ecp').with_source('https://localhost/arcgis/authorization.ecp') }
          it { is_expected.to contain_file('/opt/arcgis/software/license/authorization.ecp').that_requires('Archive[/opt/arcgis/software/license/authorization.ecp]') }
          it { is_expected.to contain_file('/opt/arcgis/software/license/authorization.ecp').with_owner('arcgis') }
          it { is_expected.to contain_file('/opt/arcgis/software/license/authorization.ecp').with_group('arcgis') }
          it { is_expected.to contain_file('/opt/arcgis/software/license/authorization.ecp').with_mode('0644') }
        end
      end

      context 'non-defaults' do
        let(:facts) { os_facts }
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
              version           => '10.5.1',
              install_dir       => '/data',
              run_as_user       => 'esri',
              run_as_user_group => 'esri',
              run_as_user_home  => '/usr/home/esri',
              license_file_uri  => 'https://localhost/some/path/license-10.5.1.ecp',
            }
          EOS
        end

        context 'check compile with globals' do
          it { is_expected.to compile }
        end

        context 'check static info' do
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').that_requires('File[/etc/arcgis]') }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"current_version": "10.5.1"}) }
          # TODO: supported_versions
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_base": "/data"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_arcgis": "/data/arcgis"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software": "/data/arcgis/software"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_archives": "/data/arcgis/software/archives"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_setup": "/data/arcgis/software/setup"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_license": "/data/arcgis/software/license"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_software_temp": "/data/arcgis/software/tmp"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_server_install": "/data/arcgis/server"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_web_adaptor_install": "/data/arcgis/webadaptor10.5.1"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_portal_install": "/data/arcgis/portal"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"path_data_store_install": "/data/arcgis/datastore"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"license_file": "/data/arcgis/software/license/license-10.5.1.ecp"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"service_user": "esri"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"service_user_home": "/usr/home/esri"}) }
          it { is_expected.to contain_file('/etc/arcgis/puppet_data.json').with_content(%r{"server_tools_dir": "/data/arcgis/server/tools"}) }
        end

        context 'check base dirs' do
          # Make sure arcgis group can write to the arcgis folder or installs will fail
          it { is_expected.to contain_file('/data/arcgis').with_owner('root') }
          it { is_expected.to contain_file('/data/arcgis').with_group('esri') }
          it { is_expected.to contain_file('/data/arcgis').with_mode('0775') }
          it { is_expected.to contain_file('/data/arcgis/software') }
          it { is_expected.to contain_file('/data/arcgis/software/archives') }
          it { is_expected.to contain_file('/data/arcgis/software/archives/10.5.1') }
          it { is_expected.to contain_file('/data/arcgis/software/setup') }
          it { is_expected.to contain_file('/data/arcgis/software/setup/10.5.1') }
          it { is_expected.to contain_file('/data/arcgis/software/license') }
          it { is_expected.to contain_file('/data/arcgis/software/tmp') }
          it { is_expected.to contain_file('/data/arcgis/software/tmp').with_owner('esri') }
          it { is_expected.to contain_file('/data/arcgis/software/tmp').with_group('esri') }
          it { is_expected.to contain_file('/data/arcgis/software/tmp').with_mode('1770') }
          it { is_expected.to contain_archive('/data/arcgis/software/license/license-10.5.1.ecp').with_source('https://localhost/some/path/license-10.5.1.ecp') }
          it { is_expected.to contain_file('/data/arcgis/software/license/license-10.5.1.ecp').that_requires('Archive[/data/arcgis/software/license/license-10.5.1.ecp]') }
          it { is_expected.to contain_file('/data/arcgis/software/license/license-10.5.1.ecp').with_owner('esri') }
          it { is_expected.to contain_file('/data/arcgis/software/license/license-10.5.1.ecp').with_group('esri') }
          it { is_expected.to contain_file('/data/arcgis/software/license/license-10.5.1.ecp').with_mode('0644') }
        end
      end
    end

    # TODO: check firewall
  end
end
