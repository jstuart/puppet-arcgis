require 'spec_helper'
require 'spec_helper_rspec'
require 'rspec/collection_matchers'
require 'webmock/rspec'
require 'time'

# Unfortunately this can't use the normal shared examples because it
# uses 3 different API endpoints.
describe Puppet::Type.type(:arcgis_site).provider(:ruby) do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      let(:name) { 'arcgis' }

      let(:no_site_json) do
        {
          status: 'error',
          messages: [
            "Server machine 'ARCGIS.INTERNAL.LOCAL' does not participate in any Site. Create a new Site or join an existing Site."
          ],
          code: 404,
          acceptLanguage: nil,
        }
      end

      let(:unauth_site_json) do
        {
          status: 'error',
          messages: [
            "Unauthorized access. Token not found. You can generate a token using the 'generateToken' operation."
          ],
          code: 499,
        }
      end

      let(:log_settings_update_json) do
        {
          status: 'success',
          settings: {
            logDir: '/opt/arcgis/data/server/logs-moved/',
            logLevel: 'WARNING',
            maxErrorReportsCount: 10,
            maxLogFileAge: 90,
            usageMeteringEnabled: false,
            statisticsConfig: {
              enabled: true,
              samplingInterval: 30,
              maxHistory: 0,
              statisticsDir: '/opt/arcgis/server/usr/directories/arcgissystem'
            }
          }
        }
      end

      let(:log_settings) do
        {
          settings: {
            logDir: '/opt/arcgis/data/server/logs/',
            logLevel: 'INFO',
            maxErrorReportsCount: 10,
            maxLogFileAge: 90,
            usageMeteringEnabled: false,
            statisticsConfig: {
              enabled: true,
              samplingInterval: 30,
              maxHistory: 0,
              statisticsDir: '/opt/arcgis/server/usr/directories/arcgissystem',
            },
          },
        }
      end

      let(:config_store_update_json) do
        {
          status: 'success'
        }
      end

      let(:config_store) do
        {
          type: 'FILESYSTEM',
          connectionString: '/opt/arcgis/data/server/config-store',
          localRepositoryPath: '/opt/arcgis/server/usr/local',
          status: 'Ready',
        }
      end

      let(:create_resource) { Puppet::Type::Arcgis_site.new create_props }

      let(:create_provider) { described_class.new create_resource }

      let(:create_props) do
        {
          ensure: 'present',
          name: 'arcgis',
          configdir: '/opt/arcgis/data/server/config-store',
          configstoretype: 'FILESYSTEM',
          logdir: '/opt/arcgis/data/server/logs',
          serverloglevel: 'VERBOSE',
          logmaxerrorreports: 20,
          logmaxfileage: 30,
        }
      end

      let(:create_json) do
        {
          status: 'success'
        }
      end

      let(:nametest_resource) { Puppet::Type::Arcgis_site.new create_props }

      let(:nametest_provider) { described_class.new create_resource }

      let(:nametest_props) do
        {
          ensure: 'present',
          name: 'arcgistest',
          configdir: '/opt/arcgis/data/server/config-store',
        }
      end

      let(:update_resource) { Puppet::Type::Arcgis_site.new update_props }

      let(:update_provider) { described_class.new update_resource }

      let(:update_props) do
        {
          ensure: 'present',
          name: 'arcgis',
          configdir: '/opt/arcgis/data/server/config-store-moved',
          configstoretype: 'FILESYSTEM',
          logdir: '/opt/arcgis/data/server/logs-moved',
          serverloglevel: 'WARNING',
          logmaxerrorreports: 15,
          logmaxfileage: 95,
        }
      end

      let(:delete_resource) { Puppet::Type::Arcgis_site.new delete_props }

      let(:delete_provider) { described_class.new delete_resource }

      let(:delete_props) do
        {
          ensure: 'absent',
          name: 'arcgis',
          configdir: '/opt/arcgis/data/server/config-store',
        }
      end

      let(:delete_json) {
        {
          status: 'success'
        }
      }

      describe 'instances' do
        it { expect(described_class).to respond_to :instances }
      end

      describe 'prefetch' do
        it { expect(described_class).to respond_to :prefetch }
      end

      context 'without a site' do
        before do
          # Stub no site
          stub_request(:get, 'http://localhost:6080/arcgis/admin/?f=json').
            with(
              headers: {
                'Accept'=>'*/*',
              },
            ).
            to_return(
              status: 200,
              body: JSON.dump(no_site_json),
            )

          # Stub creation
          stub_request(:post, "http://localhost:6080/arcgis/admin/createNewSite?f=json").
            with(
              #body: {"client"=>"requestip", "expiration"=>"5", "password"=>"admin", "username"=>"admin"},
              headers: {
                'Accept'=>'*/*',
                'Content-Type'=>'application/x-www-form-urlencoded',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(create_json)
            )
        end

        context 'will return an empty instances array' do
          subject { described_class.instances }
          it { is_expected.to eq([]) }
        end

        context 'will create a site' do
          it { expect { create_provider.flush }.to_not raise_error }
        end
      end

      context 'with a site' do
        let(:token) { 'abcdefghijklmnopqrstuvwxyz' }
        let(:timestamp) { Time.now.to_i + 3600 }
        before do
          stub_request(:get, 'http://localhost:6080/arcgis/admin/?f=json').
            with(
              headers: {
                'Accept'=>'*/*',
              },
            ).
            to_return(
              status: 200,
              body: JSON.dump(unauth_site_json),
            )

          stub_request(:post, 'http://localhost:6080/arcgis/admin/generateToken?f=json').
            with(
              body: {"client"=>"requestip", "expiration"=>"5", "password"=>"admin", "username"=>"admin"},
              headers: {
                'Accept'=>'*/*',
                'Content-Type'=>'application/x-www-form-urlencoded',
              }
            ).
            to_return(
              status: 200,
              body: "{\"token\":\"#{token}\",\"expires\":\"#{timestamp}\"}"
            )

            # Stub log settings
            stub_request(:get, "http://localhost:6080/arcgis/admin/logs/settings?f=json&token=#{token}").
              with(
                headers: {
                  'Accept'=>'*/*',
                },
              ).
              to_return(
                status: 200,
                body: JSON.dump(log_settings),
              )

            # Stub config store
            stub_request(:get, "http://localhost:6080/arcgis/admin/system/configstore?f=json&token=#{token}").
              with(
                headers: {
                  'Accept'=>'*/*',
                },
              ).
              to_return(
                status: 200,
                body: JSON.dump(config_store),
              )
        end

        context 'will have only one instance' do

          subject(:instances) { described_class.instances }
          it { is_expected.to have(1).items }

          context 'with first instance' do
            subject(:instance) { instances.first }
            it { is_expected.to have_attributes(:name => 'arcgis') }
            it { is_expected.to have_attributes(:configdir => '/opt/arcgis/data/server/config-store') }
            it { is_expected.to have_attributes(:logdir => '/opt/arcgis/data/server/logs/') }
            it { is_expected.to have_attributes(:serverloglevel => 'INFO') }
            it { is_expected.to have_attributes(:logmaxerrorreports => 10) }
            it { is_expected.to have_attributes(:logmaxfileage => 90) }
            it { is_expected.to have_attributes(:configstoretype => 'FILESYSTEM') }
          end
        end

        context 'will update the site' do
          before do
            # Stub the log setting update
            stub_request(:post, "http://localhost:6080/arcgis/admin/system/configstore/edit?f=json&token=#{token}").
              with(
                headers: {
                  'Accept'=>'*/*',
                },
              ).
              to_return(
                status: 200,
                body: JSON.dump(config_store_update_json),
              )

            # Stub the log setting update
            stub_request(:post, "http://localhost:6080/arcgis/admin/logs/settings/edit?f=json&token=#{token}").
              with(
                headers: {
                  'Accept'=>'*/*',
                },
              ).
              to_return(
                status: 200,
                body: JSON.dump(log_settings_update_json),
              )
          end

          subject(:provider) { update_provider }
          it { expect { provider.flush }.to_not raise_error }

        end

        context 'will delete the site' do
          before do
            # Stub the delete
            stub_request(:post, "http://localhost:6080/arcgis/admin/deleteSite?f=json&token=#{token}").
              with(
                headers: {
                  'Accept'=>'*/*',
                },
              ).
              to_return(
                status: 200,
                body: JSON.dump(delete_json),
              )
          end

          it { expect { delete_provider.flush }.to_not raise_error }
        end
      end
    end
  end
end
