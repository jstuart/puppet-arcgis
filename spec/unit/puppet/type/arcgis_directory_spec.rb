require 'spec_helper'

describe Puppet::Type.type(:arcgis_directory) do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      describe 'validating attributes' do
        [ :name ].each do |param|
          it "should have a #{param} parameter" do
            expect(described_class.attrtype(param)).to eq(:param)
          end
        end

        [ :ensure, :physicalpath, :directorytype, :cleanupmode, :maxfileage, :description ].each do |prop|
          it "should have a #{prop} property" do
            expect(described_class.attrtype(prop)).to eq(:property)
          end
        end

        it "should have :name as its namevar" do
          expect(described_class.key_attributes).to eq([:name])
        end
      end

      describe 'validating attribute values' do
        describe 'ensure' do
          [ :present, :absent ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => value,
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
              })}.not_to raise_error
            end
          end

          it "should not support other values" do
            expect { described_class.new({
              :ensure => 'latest',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :directorytype => 'OUTPUT',
              :cleanupmode   => 'NONE',
              :maxfileage    => 0,
            })}.to raise_error(Puppet::Error, %r{Invalid value})
          end
        end

        describe 'physicalpath' do
          it "should be required" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :directorytype => 'OUTPUT',
              :cleanupmode   => 'NONE',
              :maxfileage    => 0,
            })}.to raise_error(Puppet::Error, %r{is required})
          end

          it "should not allow nil" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => nil,
              :directorytype => 'OUTPUT',
              :cleanupmode   => 'NONE',
              :maxfileage    => 0,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ '/some/path', '/some/deeper/path/' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => value,
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
              })}.not_to raise_error
            end
          end

          [ 'some/relative/path', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => value,
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end
        end

        describe 'directorytype' do
          it "should be required" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :cleanupmode   => 'NONE',
              :maxfileage    => 0,
            })}.to raise_error(Puppet::Error, %r{is required})
          end

          it "should not allow nil" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :directorytype => nil,
              :cleanupmode   => 'NONE',
              :maxfileage    => 0,
            })}.to raise_error(Puppet::Error, %r{Got nil value})
          end

          [ 'CACHE', 'JOBS', 'OUTPUT', 'SYSTEM' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
              })}.not_to raise_error
            end
          end

          [ 'JOBREGISTRY', 'INDEX', 'INPUT', 'KML', 'UPLOADS', 'jobs', 'blah', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end
        end

        describe 'cleanupmode' do
          it "should be optional" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :directorytype => 'OUTPUT',
              :maxfileage    => 0,
            })}.not_to raise_error
          end

          # it "should allow nil" do
          #   expect { described_class.new({
          #     :ensure => 'present',
          #     :name   => 'test',
          #     :physicalpath  => '/some/path',
          #     :directorytype => 'OUTPUT',
          #     :cleanupmode   => nil,
          #     :maxfileage    => 0,
          #   })}.not_to raise_error
          # end

          [ 'NONE', 'TIME_ELAPSED_SINCE_LAST_MODIFIED' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => value,
                :maxfileage    => 0,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', 'blah', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => value,
                :maxfileage    => 0,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          [ 'JOBS', 'OUTPUT', 'SYSTEM' ].each do |value|
            it "should default to TIME_ELAPSED_SINCE_LAST_MODIFIED for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:cleanupmode]).to eq 'TIME_ELAPSED_SINCE_LAST_MODIFIED'
            end
          end

          [ 'CACHE' ].each do |value|
            it "should default to NONE for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:cleanupmode]).to eq 'NONE'
            end
          end
        end

        describe 'maxfileage' do
          it "should be optional" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :directorytype => 'OUTPUT',
              :cleanupmode   => 'NONE',
            })}.not_to raise_error
          end

          # it "should allow nil" do
          #   expect { described_class.new({
          #     :ensure => 'present',
          #     :name   => 'test',
          #     :physicalpath  => '/some/path',
          #     :directorytype => 'OUTPUT',
          #     :cleanupmode   => 'NONE',
          #     :maxfileage    => nil,
          #   })}.not_to raise_error
          # end

          [ '0', '720', 0, 720 ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => value,
              })}.not_to raise_error
            end
          end

          [ 'OTHER', '10.5', 10.5, '', ' ' ].each do |value|
            it "should not support other values" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => value,
              })}.to raise_error(Puppet::Error, %r{Invalid value})
            end
          end

          [ 'JOBS' ].each do |value|
            it "should default to 360 for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:maxfileage]).to eq 360
            end
          end

          [ 'OUTPUT' ].each do |value|
            it "should default to 10 for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:maxfileage]).to eq 10
            end
          end

          [ 'SYSTEM' ].each do |value|
            it "should default to 1440 for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:maxfileage]).to eq 1440
            end
          end

          [ 'CACHE' ].each do |value|
            it "should default to 0 for #{value}" do
              expect(described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => value,
              })[:maxfileage]).to eq 0
            end
          end
        end

        describe 'description' do
          it "should be optional" do
            expect { described_class.new({
              :ensure => 'present',
              :name   => 'test',
              :physicalpath  => '/some/path',
              :directorytype => 'OUTPUT',
              :cleanupmode   => 'NONE',
            })}.not_to raise_error
          end

          [ '', ' ', 0, 'text', 'longer text' ].each do |value|
            it "should support #{value} as a value" do
              expect { described_class.new({
                :ensure => 'present',
                :name   => 'test',
                :physicalpath  => '/some/path',
                :directorytype => 'OUTPUT',
                :cleanupmode   => 'NONE',
                :maxfileage    => 0,
                :description   => value
              })}.not_to raise_error
            end
          end
        end
      end
    end
  end
end
