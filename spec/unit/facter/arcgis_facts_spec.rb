require 'spec_helper'
# require 'webmock/rspec'
require 'facter/arcgis_facts'

describe 'arcgis facts' do
  before(:each) do
    Facter.clear
  end

  context 'when clean system' do
    before(:each) do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with('/etc/arcgis/puppet_data.json').and_return(false)
    end

    describe 'arcgis_puppet_init_done' do
      it 'checks for first run' do
        expect(Facter.fact(:arcgis_puppet_init_done).value)
          .to eq(false)
      end
    end
  end

  # context 'when installed' do
  #   before(:each) do
  #     allow(File).to receive(:exist?).and_return(false)
  #     allow(File).to receive(:exist?).with('/etc/arcgis/puppet_data.json').and_return(true)
  #     allow(File).to receive(:exist?).with('/opt/arcgis').and_return(true)
  #   end
  #
  #   describe 'arcgis_puppet_init_done' do
  #     it 'checks for first run' do
  #       expect(Facter.fact(:arcgis_puppet_init_done).value)
  #         .to eq(true)
  #     end
  #   end
  # end
  #
  # context 'override values' do
  #   before(:each) do
  #     allow(File).to receive(:exist?).and_return(false)
  #     allow(File).to receive(:read).and_return('')
  #     allow(File).to receive(:exist?).with('/etc/arcgis/puppet_data.json').and_return(true)
  #     allow(File).to receive(:read).with('/etc/arcgis/puppet_data.json').and_return('{"path_arcgis": "/data/arcgis"}')
  #   end
  #
  #   describe 'first_run' do
  #     it 'checks for first run without existing' do
  #       allow(File).to receive(:exist?).with('/data/arcgis').and_return(false)
  #       expect(Facter.fact(:arcgis_first_run).value)
  #         .to eq(true)
  #     end
  #
  #     it 'checks for first run with existing' do
  #       allow(File).to receive(:exist?).with('/data/arcgis').and_return(true)
  #       expect(Facter.fact(:arcgis_first_run).value)
  #         .to eq(false)
  #     end
  #   end
  # end
end
