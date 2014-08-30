require 'spec_helper'

describe 'supervisor' do
  let (:facts) { {
    :osfamily => 'debian',
  } }

  context "with defaults" do
    it {
      should create_file('/etc/logrotate.d/supervisor')
      should create_file('/etc/supervisor/supervisord.conf') \
        .with_content(/file=\/var\/run\/supervisor\.sock/) \
        .with_content(/chmod=0700/)
        .with_notify('Service[supervisor]')
    }
  end

  context "with unix server params" do
    let (:params) { {
      :unix_server_file  => '/tmp/supervisor.sock',
      :unix_server_chmod => '0770',
      :unix_server_chown => 'root:supervisor'
    } }
    it {
      should create_file('/etc/supervisor/supervisord.conf') \
        .with_content(/file=\/tmp\/supervisor\.sock/) \
        .with_content(/chmod=0770/)
        .with_content(/chown=root:supervisor/)
        .with_notify('Service[supervisor]')
    }
  end

  context "with enable_logrotate=false" do
    let (:params) { {
      :enable_logrotate => false
    } }
    it {
      should_not create_file('/etc/logrotate.d/supervisor')
    }
  end

  context "with configured conf_dir" do
    let (:params) { {
      :conf_dir => '/some/dir',
    } }

    it "should create configured conf_dir" do
      should create_file('/some/dir').with_ensure('directory')
    end
  end

  context "with include_files" do
    let(:params) { {
      :include_files     => ['/etc/someconfig', '/etc/somewhereelse/*.conf'],
    } }
    it {
      should create_file('/etc/supervisor/supervisord.conf') \
        .with_content(%r{files = .* /etc/someconfig /etc/somewhereelse/\*\.conf$})
    }
  end
end
