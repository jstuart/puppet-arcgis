require 'spec_helper'

describe Puppet::Type.type(:arcgis_site) do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'validating attributes' do
        [ :name ].each do |param|
          it "should have a #{param} parameter" do
            expect(described_class.attrtype(param)).to eq(:param)
          end
        end

        [ :ensure, :configdir, :configstoretype, :logdir, :serverloglevel, :logmaxerrorreports, :logmaxfileage ].each do |prop|
          it "should have a #{prop} property" do
            expect(described_class.attrtype(prop)).to eq(:property)
          end
        end

        it 'should have :name as its namevar' do
          expect(described_class.key_attributes).to eq([:name])
        end
      end

      describe 'validating attribute values' do
        describe 'ensure' do
          [ :present, :absent ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: value,
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
              })}.not_to raise_error
            end
          end

          it 'should not support other values' do
            expect { described_class.new({
              ensure: 'latest',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })}.to raise_error(Puppet::Error, %r{Invalid value})
          end
        end

        describe 'name' do
          it 'should should succeed even if not arcgis' do
            expect { described_class.new({
              ensure: 'present',
              name: 'othervalue',
              configdir: '/opt/arcgis/data/server/config',
            })}.not_to raise_error
          end

          it 'should convert values to arcgis' do
            expect(described_class.new({
              ensure: 'present',
              name: 'othervalue',
              configdir: '/opt/arcgis/data/server/config',
            })[:name]).to eq 'arcgis'
          end
        end

        describe 'configdir' do
          it "should be required" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
            })}.to raise_error(Puppet::Error, %r{is required})
          end

          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ '/some/path', '/some/deeper/path/' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: value,
              })}.not_to raise_error
            end
          end

          [ 'some/relative/path', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end
        end

        describe 'configstoretype' do
          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              configstoretype: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ 'FILESYSTEM' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                configstoretype: value,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                configstoretype: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          it 'should default to FILESYSTEM' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })[:configstoretype]).to eq :FILESYSTEM
          end
        end

        describe 'logdir' do
          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              logdir: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ '/some/path', '/some/deeper/path/' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logdir: value,
              })}.not_to raise_error
            end
          end

          [ 'some/relative/path', '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logdir: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          it 'should default to /var/log/arcgis' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })[:logdir]).to eq '/var/log/arcgis/'
          end

          it 'should add a trailing slash if one is not given' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              logdir: '/opt/arcgis/data/server/logs',
            })[:logdir]).to eq '/opt/arcgis/data/server/logs/'
          end

          it 'should not add a trailing slash if one is given' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              logdir: '/opt/arcgis/data/server/logs/',
            })[:logdir]).to eq '/opt/arcgis/data/server/logs/'
          end
        end

        describe 'serverloglevel' do
          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              serverloglevel: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ 'OFF', 'SEVERE', 'WARNING', 'INFO', 'FINE', 'VERBOSE', 'DEBUG' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                serverloglevel: value,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                serverloglevel: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          it 'should default to WARNING' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })[:serverloglevel]).to eq :WARNING
          end
        end

        describe 'logmaxerrorreports' do
          it "should be optional" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })}.not_to raise_error
          end

          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              logmaxerrorreports: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ '0', '100', 0, 100 ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logmaxerrorreports: value,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', '10.5', 10.5, '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logmaxerrorreports: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          it 'should default to 10' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })[:logmaxerrorreports]).to eq 10
          end
        end

        describe 'logmaxfileage' do
          it "should be optional" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })}.not_to raise_error
          end

          it "should not allow nil" do
            expect { described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
              logmaxfileage: nil,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ '0', '100', 0, 100 ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logmaxfileage: value,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', '10.5', 10.5, '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                ensure: 'present',
                name: 'arcgis',
                configdir: '/opt/arcgis/data/server/config',
                logmaxfileage: value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          it 'should default to 10' do
            expect(described_class.new({
              ensure: 'present',
              name: 'arcgis',
              configdir: '/opt/arcgis/data/server/config',
            })[:logmaxfileage]).to eq 90
          end
        end

      end
    end
  end
end
