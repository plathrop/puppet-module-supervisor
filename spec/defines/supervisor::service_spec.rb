require 'spec_helper'

describe 'supervisor::service' do
  let (:facts) { {
    :osfamily => 'debian',
  } }
  let(:title) { 'sometitle' }
  let(:params) { {
    :command     => 'somecommand',
  } }

  context "with debian configuration" do
    let (:pre_condition) {
      <<-PUPPET
        class { 'supervisor':
          conf_dir => '/etc/supervisor/conf.d',
          conf_ext => '.conf',
        }
      PUPPET
    }


    it "should include /etc/supervisor/conf.d/*.conf in /etc/supervisor/supervisord.conf" do
      should create_file('/etc/supervisor/supervisord.conf') \
          .with_content(Regexp.new Regexp.escape 'files = /etc/supervisor/conf.d/*.conf')
    end

    it "should create /etc/supervisor/conf.d/sometitle.conf" do
      should create_file('/etc/supervisor/conf.d/sometitle.conf') \
          .with_content(Regexp.new Regexp.escape 'command=somecommand')
    end
  end

  context "with default configuration" do

    it "should include /etc/supervisor/*.ini in /etc/supervisor/supervisord.conf" do
      should contain_file('/etc/supervisor/supervisord.conf') \
          .with_content(Regexp.new Regexp.escape 'files = /etc/supervisor/*.ini')
    end

    it "should create /etc/supervisor/sometitle.ini" do
      should create_file('/etc/supervisor/sometitle.ini') \
          .with_content(Regexp.new Regexp.escape 'command=somecommand')
    end
    it {
      should contain_service("supervisor::#{title}").with(
        'ensure'     => 'running',
        'provider'   => 'base',
        'restart'    => "/usr/bin/supervisorctl restart sometitle | awk '/^sometitle[: ]/{print \$2}' | grep -Pzo '^stopped\\nstarted$'",
        'start'      => "/usr/bin/supervisorctl start sometitle | awk '/^sometitle[: ]/{print \$2}' | grep '^started$'",
        'status'     => "/usr/bin/supervisorctl status | awk 'BEGIN { RS = \"\\n\" } /^sometitle_?\\d*/ { if (\$2 !~ /^(STARTING|RUNNING)/) { exit 1 } }'",
        'stop'       => "/usr/bin/supervisorctl stop sometitle | awk '/^sometitle[: ]/{print \$2}' | grep '^stopped$'",
      )
    }
  end

end
