require 'spec_helper'

describe 'arcgis::patch' do
  let(:title) { 'S-1051-P-78B' }
  let(:params) do
    {
      archive_file: 'ArcGIS-1051-S-SEC2018U1-PatchB-linux.tar',
      archive_sha1: 'bcee61416d330057215fd5b50edb022f0c80ae0b',
      type: 'server',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        os_facts.merge(
          arcgis_installed_qfe_ids: nil
        )
      end

      it { is_expected.to compile }
    end
  end
end
