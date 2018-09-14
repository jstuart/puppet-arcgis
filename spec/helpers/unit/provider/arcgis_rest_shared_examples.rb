require 'json'
require 'spec_helper_rspec'
require 'webmock/rspec'
require 'time'

# FIXME: defaults below should change to whatever is most common
shared_examples 'REST API' do |resource_endpoint, create_endpoint = 'register', update_endpoint = 'edit', delete_endpoint = 'unregister', singleton = false|

  describe 'authenticated' do
    let(:token) { 'abcdefghijklmnopqrstuvwxyz' }
    let(:timestamp) { Time.now.to_i + 3600 }
    before :each do
      stub_request(:post, "http://localhost:6080/arcgis/admin/generateToken?f=json").
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
    end

    describe 'instances' do
      context "with no #{resource_endpoint}s" do
        let(:json) { list_empty }
        let(:expected) { list_empty_expected }

        it 'returns an empty list' do
          stub_request(:get, "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}")
            .with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(json),
            )

          expect(described_class.instances).to eq(expected)
        end
      end

      context "with #{resource_endpoint}s" do
        let(:json) { list_success }
        let(:expected) { list_success_expected }

        it 'returns an empty list' do
          stub_request(:get, "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}")
            .with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(json),
            )

          # TODO: validate content somehow
          expect(described_class.instances).to be_instance_of(Array)
        end
      end

      describe 'flush to create' do
        let(:list_json) { list_empty }
        let(:item_json) { retrieve_noitem }
        let(:create_json) { create_success }

        let(:action_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{create_endpoint}?f=json&token=#{token}" }
        if singleton
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}" }
        else
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{name}?f=json&token=#{token}" }
        end

        it "creates #{resource_endpoint}s" do

          # Stub creation
          stub_request(:post, "http://localhost:6080/arcgis/#{resource_endpoint}/#{create_endpoint}?f=json&token=#{token}").
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

          # Stub instance list
          stub_request(:get, "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}").
            with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(list_json),
            )

          # Stub item retrieval
          stub_request(:get, item_uri).
            with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(item_json),
            )

          create_provider.flush
        end
      end

      describe 'flush to update' do
        let(:list_json) { list_success }
        let(:item_json) { retrieve_success }
        let(:update_json) { update_success }

        if singleton
          let(:action_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{update_endpoint}?f=json&token=#{token}" }
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}" }
        else
          let(:action_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{name}/#{update_endpoint}?f=json&token=#{token}" }
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{name}?f=json&token=#{token}" }
        end

        it "updates #{resource_endpoint}s" do

          # Stub update
          stub_request(:post, action_uri).
            with(
              #body: {"client"=>"requestip", "expiration"=>"5", "password"=>"admin", "username"=>"admin"},
              headers: {
                'Accept'=>'*/*',
                'Content-Type'=>'application/x-www-form-urlencoded',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(update_json)
            )

          # Stub instance list
          stub_request(:get, "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}").
            with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(list_json),
            )

        # Stub item retrieval
        stub_request(:get, item_uri).
          with(
            headers: {
              'Accept'=>'*/*',
            }
          ).
          to_return(
            status: 200,
            body: JSON.dump(item_json),
          )

          update_provider.flush
        end
      end

      describe 'flush to delete' do
        let(:list_json) { list_success }
        let(:item_json) { retrieve_success }
        let(:delete_json) { delete_success }

        if singleton
          let(:action_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{delete_endpoint}?f=json&token=#{token}" }
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}" }
        else
          let(:action_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{name}/#{delete_endpoint}?f=json&token=#{token}" }
          let(:item_uri) { "http://localhost:6080/arcgis/#{resource_endpoint}/#{name}?f=json&token=#{token}" }
        end

        it "deletes #{resource_endpoint}s" do

          # Stub deletion
          stub_request(:post, action_uri).
            with(
              #body: {"client"=>"requestip", "expiration"=>"5", "password"=>"admin", "username"=>"admin"},
              headers: {
                'Accept'=>'*/*',
                'Content-Type'=>'application/x-www-form-urlencoded',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(delete_json)
            )

          # Stub instance list
          stub_request(:get, "http://localhost:6080/arcgis/#{resource_endpoint}?f=json&token=#{token}").
            with(
              headers: {
                'Accept'=>'*/*',
              }
            ).
            to_return(
              status: 200,
              body: JSON.dump(list_json),
            )

        # Stub item retrieval
        stub_request(:get, item_uri).
          with(
            headers: {
              'Accept'=>'*/*',
            }
          ).
          to_return(
            status: 200,
            body: JSON.dump(item_json),
          )

          delete_provider.flush
        end
      end
    end
  end
end
