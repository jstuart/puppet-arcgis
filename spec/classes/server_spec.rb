require 'spec_helper'

describe 'arcgis::server' do
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
    context 'with server' do
      service_provider = (os_facts[:operatingsystemmajrelease] == '7') ? 'systemd' : 'redhat'
      let(:facts) do
        os_facts.merge(service_provider: service_provider)
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

        context 'will have common include' do
          it { is_expected.to contain_class('arcgis::common') }
        end

        context 'will have required packages' do
          it { is_expected.to contain_package('libXtst') }
        end

        context 'will have archive' do
          it {
            is_expected.to contain_archive('ArcGIS_Server_Linux_1061_164044.tar.gz').with(
              path:         '/opt/arcgis/software/archives/10.6.1/ArcGIS_Server_Linux_1061_164044.tar.gz',
              source:       'https://localhost/10.6.1/ArcGIS_Server_Linux_1061_164044.tar.gz',
              checksum:     '1234567890123456789012345678901234567890',
              extract:      true,
              extract_path: '/opt/arcgis/software/setup/10.6.1',
              creates:      '/opt/arcgis/software/setup/10.6.1/ArcGISServer/Setup',
              cleanup:      false,
              user:         'arcgis',
              group:        'arcgis',
            )
          }

          it {
            is_expected.to contain_archive('ArcGIS_Server_Linux_1061_164044.tar.gz').that_requires(
              [
                'Class[arcgis::common]',
                'Package[libXtst]',
              ],
            )
          }
        end

        context 'will have install command' do
          it {
            is_expected.to contain_exec('arcgis-server-install').with(
              command: "sudo -u arcgis bash -c '/opt/arcgis/software/setup/10.6.1/ArcGISServer/Setup -m silent -l yes -d \"/opt\"'",
              cwd:     '/opt',
              user:    'root',
              group:   'root',
              umask:   '027',
              path:    '/bin:/sbin:/usr/bin:/usr/sbin',
              timeout: '7200',
              creates: '/opt/arcgis/server/startserver.sh',
            )
          }

          it { is_expected.to contain_exec('arcgis-server-install').that_requires('Archive[ArcGIS_Server_Linux_1061_164044.tar.gz]') }
        end

        context 'will have authorization command' do
          it {
            is_expected.to contain_exec('arcgis-server-authorize').with(
              command: '/opt/arcgis/server/tools/authorizeSoftware -f /opt/arcgis/software/license/authorization.ecp',
              cwd:     '/opt',
              user:    'arcgis',
              group:   'arcgis',
              umask:   '027',
              path:    '/bin:/sbin:/usr/bin:/usr/sbin',
              timeout: '7200',
              unless:  "bash -c 'output=\"$(/opt/arcgis/server/tools/authorizeSoftware -s)\" && echo \$output | grep -qv \"Not Authorized\"'",
            )
          }

          it { is_expected.to contain_exec('arcgis-server-authorize').that_requires('Exec[arcgis-server-install]') }
        end

        context 'will have service file' do
          if os_facts[:operatingsystemmajrelease] == '7'
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_ensure('present') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^# ArcGIS Server systemd unit file}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^User=arcgis$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^ExecStart=/opt/arcgis/server/startserver.sh$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^ExecStop=/opt/arcgis/server/stopserver.sh$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_requires('Exec[arcgis-server-install]') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_comes_before('Service[arcgisserver]') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_notifies('Service[arcgisserver]') }
          elsif os_facts[:operatingsystemmajrelease] == '6'
            it {
              is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with(
                ensure: 'present',
                owner:  'root',
                group:  'root',
                mode:   '0755',
              )
            }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^# Description: ArcGIS Server Service}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^# chkconfig: 35 99 01$}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^agshome=/opt/arcgis/server$}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_requires('Exec[arcgis-server-install]') }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_comes_before('Service[arcgisserver]') }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_notifies('Service[arcgisserver]') }
          end
        end

        context 'will have service' do
          it {
            is_expected.to contain_service('arcgisserver').with(
              ensure: 'running',
              enable: true,
            )
          }
          it { is_expected.to contain_service('arcgisserver').that_requires('Exec[arcgis-server-install]') }
        end

        context 'will have arcgis_site' do
          it {
            is_expected.to contain_arcgis_site('arcgis').with(
              ensure: 'present',
              configstoretype: 'FILESYSTEM',
              configdir: '/opt/arcgis/data/server/config-store',
              logdir: '/opt/arcgis/data/server/logs',
              serverloglevel: 'INFO',
              logmaxerrorreports: 10,
              logmaxfileage: 90,
            )
          }

          it { is_expected.to contain_arcgis_site('arcgis').that_requires('Service[arcgisserver]') }
        end

        context 'will have arcgis_directory types' do
          it {
            is_expected.to contain_arcgis_directory('arcgiscache').with(
              ensure: 'present',
              physicalpath: '/opt/arcgis/data/server/cache',
              directorytype: 'CACHE',
              cleanupmode: 'NONE',
              maxfileage: 0,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgiscache').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgisjobs').with(
              ensure: 'present',
              physicalpath: '/opt/arcgis/data/server/jobs',
              directorytype: 'JOBS',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 360,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgisjobs').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgisoutput').with(
              ensure: 'present',
              physicalpath: '/opt/arcgis/data/server/output',
              directorytype: 'OUTPUT',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 10,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgisoutput').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgissystem').with(
              ensure: 'present',
              physicalpath: '/opt/arcgis/data/server/system',
              directorytype: 'SYSTEM',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 1440,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgissystem').that_requires('Arcgis_site[arcgis]') }
        end
      end

      context 'will work with non-default globals' do
        let(:pre_condition) do
          <<-EOS
            class { 'arcgis::globals':
              version           => '10.5.1',
              archive_base_uri  => 'https://my.server.local/path',
              install_dir       => '/data',
              run_as_user       => 'esri',
              run_as_user_group => 'esri',
              run_as_user_home  => '/usr/home/esri',
              license_file_uri  => 'https://localhost/some/path/license-10.5.1.ecp',
              data_base_dir     => '/my/data/storage',

              install_system_requirements => false,

              server_log_level         => 'SEVERE',
              server_max_error_reports => 5,
              server_max_log_file_age  => 60,

              server_max_jobs_file_age   => 300,
              server_max_output_file_age => 5,
              server_max_system_file_age => 1000,
            }
          EOS
        end

        context 'will compile with globals' do
          it { is_expected.to compile }
        end

        context 'will have common include' do
          it { is_expected.to contain_class('arcgis::common') }
        end

        context 'will have required packages' do
          it { is_expected.not_to contain_package('libXtst') }
        end

        context 'will have archive' do
          it {
            is_expected.to contain_archive('ArcGIS_Server_Linux_1051_156429.tar.gz').with(
              path:         '/data/arcgis/software/archives/10.5.1/ArcGIS_Server_Linux_1051_156429.tar.gz',
              source:       'https://my.server.local/path/10.5.1/ArcGIS_Server_Linux_1051_156429.tar.gz',
              checksum:     'b2a956a5d62770ee22f7de063bbd52a209ea94bb',
              extract:      true,
              extract_path: '/data/arcgis/software/setup/10.5.1',
              creates:      '/data/arcgis/software/setup/10.5.1/ArcGISServer/Setup',
              cleanup:      false,
              user:         'esri',
              group:        'esri',
            )
          }

          it { is_expected.to contain_archive('ArcGIS_Server_Linux_1051_156429.tar.gz').that_requires('Class[arcgis::common]') }
          it { is_expected.not_to contain_archive('ArcGIS_Server_Linux_1051_156429.tar.gz').that_requires('Package[libXtst]') }
        end

        context 'will have install command' do
          it {
            is_expected.to contain_exec('arcgis-server-install').with(
              command: "sudo -u esri bash -c '/data/arcgis/software/setup/10.5.1/ArcGISServer/Setup -m silent -l yes -d \"/data\"'",
              cwd:     '/data',
              user:    'root',
              group:   'root',
              umask:   '027',
              path:    '/bin:/sbin:/usr/bin:/usr/sbin',
              timeout: '7200',
              creates: '/data/arcgis/server/startserver.sh',
            )
          }

          it { is_expected.to contain_exec('arcgis-server-install').that_requires('Archive[ArcGIS_Server_Linux_1051_156429.tar.gz]') }
        end

        context 'will haveserver_max_jobs_file_age authorize command' do
          it {
            is_expected.to contain_exec('arcgis-server-authorize').with(
              command: '/data/arcgis/server/tools/authorizeSoftware -f /data/arcgis/software/license/license-10.5.1.ecp',
              cwd:     '/data',
              user:    'esri',
              group:   'esri',
              umask:   '027',
              path:    '/bin:/sbin:/usr/bin:/usr/sbin',
              timeout: '7200',
              unless:  "bash -c 'output=\"$(/data/arcgis/server/tools/authorizeSoftware -s)\" && echo \$output | grep -qv \"Not Authorized\"'",
            )
          }

          it { is_expected.to contain_exec('arcgis-server-authorize').that_requires('Exec[arcgis-server-install]') }
        end

        context 'will have service file' do
          if os_facts[:operatingsystemmajrelease] == '7'
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_ensure('present') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^# ArcGIS Server systemd unit file}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^User=esri$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^ExecStart=/data/arcgis/server/startserver.sh$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').with_content(%r{^ExecStop=/data/arcgis/server/stopserver.sh$}) }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_requires('Exec[arcgis-server-install]') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_comes_before('Service[arcgisserver]') }
            it { is_expected.to contain_systemd__unit_file('arcgisserver.service').that_notifies('Service[arcgisserver]') }
          elsif os_facts[:operatingsystemmajrelease] == '6'
            it {
              is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with(
                ensure: 'present',
                owner:  'root',
                group:  'root',
                mode:   '0755',
              )
            }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^# Description: ArcGIS Server Service$}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^# chkconfig: 35 99 01$}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').with_content(%r{^agshome=/data/arcgis/server$}) }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_requires('Exec[arcgis-server-install]') }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_comes_before('Service[arcgisserver]') }
            it { is_expected.to contain_file('/etc/rc.d/init.d/arcgisserver').that_notifies('Service[arcgisserver]') }
          end
        end

        context 'will have service' do
          it {
            is_expected.to contain_service('arcgisserver').with(
              ensure: 'running',
              enable: true,
            )
          }
          it { is_expected.to contain_service('arcgisserver').that_requires('Exec[arcgis-server-install]') }
        end

        context 'will have arcgis_site' do
          it {
            is_expected.to contain_arcgis_site('arcgis').with(
              ensure: 'present',
              configstoretype: 'FILESYSTEM',
              configdir: '/my/data/storage/server/config-store',
              logdir: '/my/data/storage/server/logs',
              serverloglevel: 'SEVERE',
              logmaxerrorreports: 5,
              logmaxfileage: 60,
            )
          }

          it { is_expected.to contain_arcgis_site('arcgis').that_requires('Service[arcgisserver]') }
        end

        context 'will have arcgis_directory types' do
          it {
            is_expected.to contain_arcgis_directory('arcgiscache').with(
              ensure: 'present',
              physicalpath: '/my/data/storage/server/cache',
              directorytype: 'CACHE',
              cleanupmode: 'NONE',
              maxfileage: 0,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgiscache').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgisjobs').with(
              ensure: 'present',
              physicalpath: '/my/data/storage/server/jobs',
              directorytype: 'JOBS',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 300,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgisjobs').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgisoutput').with(
              ensure: 'present',
              physicalpath: '/my/data/storage/server/output',
              directorytype: 'OUTPUT',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 5,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgisoutput').that_requires('Arcgis_site[arcgis]') }

          it {
            is_expected.to contain_arcgis_directory('arcgissystem').with(
              ensure: 'present',
              physicalpath: '/my/data/storage/server/system',
              directorytype: 'SYSTEM',
              cleanupmode: 'TIME_ELAPSED_SINCE_LAST_MODIFIED',
              maxfileage: 1000,
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgissystem').that_requires('Arcgis_site[arcgis]') }
        end
      end

      context 'will allow subdir manipulation' do
        context 'will allow data dir override' do
          let(:pre_condition) do
            <<-EOS
              class { 'arcgis::globals':
                version       => '10.5.1',
                data_base_dir => '/my/data/storage',
              }
            EOS
          end

          it {
            is_expected.to contain_arcgis_site('arcgis').with(
              configdir: '/my/data/storage/server/config-store',
              logdir: '/my/data/storage/server/logs',
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgiscache').with(physicalpath: '/my/data/storage/server/cache') }
          it { is_expected.to contain_arcgis_directory('arcgisjobs').with(physicalpath: '/my/data/storage/server/jobs') }
          it { is_expected.to contain_arcgis_directory('arcgisoutput').with(physicalpath: '/my/data/storage/server/output') }
          it { is_expected.to contain_arcgis_directory('arcgissystem').with(physicalpath: '/my/data/storage/server/system') }
        end

        context 'will allow server dir override' do
          let(:pre_condition) do
            <<-EOS
              class { 'arcgis::globals':
                version              => '10.5.1',
                server_data_base_dir => '/my/data/storage',
              }
            EOS
          end

          it {
            is_expected.to contain_arcgis_site('arcgis').with(
              configdir: '/my/data/storage/config-store',
              logdir: '/my/data/storage/logs',
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgiscache').with(physicalpath: '/my/data/storage/cache') }
          it { is_expected.to contain_arcgis_directory('arcgisjobs').with(physicalpath: '/my/data/storage/jobs') }
          it { is_expected.to contain_arcgis_directory('arcgisoutput').with(physicalpath: '/my/data/storage/output') }
          it { is_expected.to contain_arcgis_directory('arcgissystem').with(physicalpath: '/my/data/storage/system') }
        end

        context 'will allow inividual dir override' do
          let(:pre_condition) do
            <<-EOS
              class { 'arcgis::globals':
                version                 => '10.5.1',
                server_data_cache_dir   => '/my/data/storage_1/arcgiscache',
                server_data_jobs_dir    => '/my/data/storage_2/arcgisjobs',
                server_data_output_dir  => '/my/data/storage_3/arcgisoutput',
                server_data_system_dir  => '/my/data/storage_4/arcgissystem',
                server_data_log_dir     => '/my/data/storage_5/arcgislogs',
                server_data_config_dir  => '/my/data/storage_6/arcgisconfig',
              }
            EOS
          end

          it {
            is_expected.to contain_arcgis_site('arcgis').with(
              configdir: '/my/data/storage_6/arcgisconfig',
              logdir: '/my/data/storage_5/arcgislogs',
            )
          }
          it { is_expected.to contain_arcgis_directory('arcgiscache').with(physicalpath: '/my/data/storage_1/arcgiscache') }
          it { is_expected.to contain_arcgis_directory('arcgisjobs').with(physicalpath: '/my/data/storage_2/arcgisjobs') }
          it { is_expected.to contain_arcgis_directory('arcgisoutput').with(physicalpath: '/my/data/storage_3/arcgisoutput') }
          it { is_expected.to contain_arcgis_directory('arcgissystem').with(physicalpath: '/my/data/storage_4/arcgissystem') }
        end
      end
    end
  end
end
