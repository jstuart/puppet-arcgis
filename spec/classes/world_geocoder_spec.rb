require 'spec_helper'

describe 'arcgis::world_geocoder' do
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
    context 'with world geocoder' do
      let(:facts) do
        os_facts
      end

      context 'will work with default globals' do
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':}
            class { 'arcgis::server':}
          EOS
        end

        context 'will compile with globals' do
          it { is_expected.to compile }
        end

        context 'will have content directory' do
          it {
            is_expected.to contain_file('/opt/arcgis/data/GeocodeService').with(
              ensure: 'directory',
              owner:  'arcgis',
              group:  'arcgis',
              mode:   '0755',
            )
          }

          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService').that_requires('Class[Arcgis::Server]') }
        end

        context 'will have configuration file' do
          it {
            is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with(
              ensure: 'present',
              owner:  'arcgis',
              group:  'arcgis',
              mode:   '0644',
            )
          }

          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^protocol = http}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^server = localhost:6080}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^portal = }) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^username = admin}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^password = admin}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^content_folder = /opt/arcgis/data/GeocodeService}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').with_content(%r{^edition = advanced}) }
          it { is_expected.to contain_file('/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini').that_requires('Archive[World_Geocoder_for_ArcGIS_1051.tar.gz]') }
        end

        context 'will have install command' do
          it {
            is_expected.to contain_exec('world-geocoder-install').with(
              command: "sudo -u arcgis bash -c '/opt/arcgis/server/tools/python /opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.py && touch /opt/arcgis/data/GeocodeService/.installed'",
              cwd:     '/opt/arcgis/data/GeocodeService/Scripts',
              user:    'root',
              group:   'root',
              umask:   '022',
              path:    '/opt/arcgis/server/tools:/bin:/sbin:/usr/bin:/usr/sbin',
              timeout: '7200',
              creates: '/opt/arcgis/data/GeocodeService/.installed',
            )
          }

          it { is_expected.to contain_exec('world-geocoder-install').that_requires('File[/opt/arcgis/data/GeocodeService/Scripts/PublishWorldGeocodeService.ini]') }
        end
      end
    end
  end
end
