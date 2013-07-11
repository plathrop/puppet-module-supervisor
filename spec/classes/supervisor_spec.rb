require 'spec_helper'

describe 'supervisor' do
  let (:facts) { {
    :osfamily => 'debian',
  } }

  context "with configured conf_dir" do
    let (:params) { {
      :conf_dir => '/some/dir',
    } }

    it "should create configured conf_dir" do
      should create_file('/some/dir').with_ensure('directory')
    end
  end
end
