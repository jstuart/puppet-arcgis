require 'spec_helper'

describe 'arcgis::web_adaptor' do
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
      let(:webapps_target) do
        (os_facts[:operatingsystemrelease] == '7') ? '/usr/share/tomcat/webapps/arcgis.war' : '/var/lib/tomcat/webapps/arcgis.war'
      end

      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will include server' do
        it { is_expected.to contain_class('arcgis::server') }
      end

      context 'will have archive' do
        it {
          is_expected.to contain_archive('Web_Adaptor_Java_Linux_1061_164057.tar.gz').with(
            path:         '/opt/arcgis/software/archives/10.6.1/Web_Adaptor_Java_Linux_1061_164057.tar.gz',
            source:       'https://localhost/10.6.1/Web_Adaptor_Java_Linux_1061_164057.tar.gz',
            checksum:     '1234567890123456789012345678901234567890',
            extract:      true,
            extract_path: '/opt/arcgis/software/setup/10.6.1',
            creates:      '/opt/arcgis/software/setup/10.6.1/WebAdaptor/Setup',
            cleanup:      false,
            user:         'arcgis',
            group:        'arcgis',
          )
        }

        it { is_expected.to contain_archive('Web_Adaptor_Java_Linux_1061_164057.tar.gz').that_requires('Class[arcgis::server]') }
      end

      context 'will have install command' do
        it {
          is_expected.to contain_exec('arcgis-web-adaptor-install').with(
            command: "sudo -u arcgis bash -c '/opt/arcgis/software/setup/10.6.1/WebAdaptor/Setup -m silent -l yes -d \"/opt\"'",
            cwd:     '/opt',
            user:    'root',
            group:   'root',
            umask:   '027',
            path:    '/bin:/sbin:/usr/bin:/usr/sbin',
            timeout: '7200',
            creates: '/opt/arcgis/webadaptor10.6.1/java/arcgis.war',
          )
        }

        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Archive[Web_Adaptor_Java_Linux_1061_164057.tar.gz]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Class[arcgis::tools::java]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Class[arcgis::tools::tomcat]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_notifies('Exec[arcgis-web-adaptor-configure]') }
      end

      context 'will have webapps symlink' do
        it {
          is_expected.to contain_file(webapps_target).with(
            ensure: 'link',
            target: '/opt/arcgis/webadaptor10.6.1/java/arcgis.war',
          )
        }

        it { is_expected.to contain_File(webapps_target).that_requires('Exec[arcgis-web-adaptor-install]') }
        it { is_expected.to contain_file(webapps_target).that_notifies('Exec[arcgis-web-adaptor-configure]') }
      end

      context 'will have config command' do
        it {
          is_expected.to contain_exec('arcgis-web-adaptor-configure').with(
            command:    "sudo -u arcgis bash -c '/opt/arcgis/webadaptor10.6.1/java/tools/configurewebadaptor.sh -m server -w \"http://localhost:8080/arcgis/webadaptor\" -g \"http://localhost:6080\" -u \"admin\" -p \"admin\" -a false'",
            cwd:        '/opt/arcgis/webadaptor10.6.1/java/tools',
            user:       'root',
            group:      'root',
            umask:      '027',
            path:       '/bin:/sbin:/usr/bin:/usr/sbin',
            timeout:    '7200',
            refreshonly: true,
          )
        }

        it { is_expected.to contain_exec('arcgis-web-adaptor-configure').that_requires("File[#{webapps_target}]") }
      end
    end

    context 'will work with non-default globals' do
      let(:webapps_target) do
        (os_facts[:operatingsystemrelease] == '7') ? '/opt/tomcat/webapps/arcgis.war' : '/opt/tomcat/webapps/arcgis.war'
      end

      let(:pre_condition) do
        <<-EOS
          class { 'arcgis::globals':
            version                  => '10.5.1',
            archive_base_uri         => 'https://my.server.local/path',
            install_dir              => '/data',
            run_as_user              => 'esri',
            run_as_user_group        => 'esri',
            run_as_user_home         => '/usr/home/esri',

            web_adaptor_mode         => 'portal',
            web_adaptor_public_uri   => 'https://my.domain.local/arcgis/webadaptor',
            web_adaptor_enable_admin => true,
            web_adaptor_webapps_dir  => '/opt/tomcat/webapps',

            psa_username             => 'foo',
            psa_password             => 'bar',
          }
        EOS
      end

      context 'will compile with globals' do
        it { is_expected.to compile }
      end

      context 'will have common include' do
        it { is_expected.to contain_class('arcgis::server') }
      end

      context 'will have archive' do
        it {
          is_expected.to contain_archive('Web_Adaptor_Java_Linux_1051_156442.tar.gz').with(
            path:         '/data/arcgis/software/archives/10.5.1/Web_Adaptor_Java_Linux_1051_156442.tar.gz',
            source:       'https://my.server.local/path/10.5.1/Web_Adaptor_Java_Linux_1051_156442.tar.gz',
            checksum:     '67fa566d67c1cd3880edb1cc65021360cc8db998',
            extract:      true,
            extract_path: '/data/arcgis/software/setup/10.5.1',
            creates:      '/data/arcgis/software/setup/10.5.1/WebAdaptor/Setup',
            cleanup:      false,
            user:         'esri',
            group:        'esri',
          )
        }

        it { is_expected.to contain_archive('Web_Adaptor_Java_Linux_1051_156442.tar.gz').that_requires('Class[arcgis::server]') }
      end

      context 'will have install command' do
        it {
          is_expected.to contain_exec('arcgis-web-adaptor-install').with(
            command: "sudo -u esri bash -c '/data/arcgis/software/setup/10.5.1/WebAdaptor/Setup -m silent -l yes -d \"/data\"'",
            cwd:     '/data',
            user:    'root',
            group:   'root',
            umask:   '027',
            path:    '/bin:/sbin:/usr/bin:/usr/sbin',
            timeout: '7200',
            creates: '/data/arcgis/webadaptor10.5.1/java/arcgis.war',
          )
        }

        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Archive[Web_Adaptor_Java_Linux_1051_156442.tar.gz]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Class[arcgis::tools::java]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_requires('Class[arcgis::tools::tomcat]') }
        it { is_expected.to contain_exec('arcgis-web-adaptor-install').that_notifies('Exec[arcgis-web-adaptor-configure]') }
      end

      context 'will have webapps symlink' do
        it {
          is_expected.to contain_file(webapps_target).with(
            ensure: 'link',
            target: '/data/arcgis/webadaptor10.5.1/java/arcgis.war',
          )
        }

        it { is_expected.to contain_file(webapps_target).that_requires('Exec[arcgis-web-adaptor-install]') }
        it { is_expected.to contain_file(webapps_target).that_notifies('Exec[arcgis-web-adaptor-configure]') }
      end

      context 'will have config command' do
        it {
          is_expected.to contain_exec('arcgis-web-adaptor-configure').with(
            command:    "sudo -u esri bash -c '/data/arcgis/webadaptor10.5.1/java/tools/configurewebadaptor.sh -m portal -w \"https://my.domain.local/arcgis/webadaptor\" -g \"http://localhost:6080\" -u \"foo\" -p \"bar\" -a true'",
            cwd:        '/data/arcgis/webadaptor10.5.1/java/tools',
            user:       'root',
            group:      'root',
            umask:      '027',
            path:       '/bin:/sbin:/usr/bin:/usr/sbin',
            timeout:    '7200',
            refreshonly: true,
          )
        }

        it { is_expected.to contain_exec('arcgis-web-adaptor-configure').that_requires("File[#{webapps_target}]") }
      end
    end
  end
end
