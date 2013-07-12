require 'spec_helper'
require 'puppetlabs_spec_helper/puppetlabs_spec/puppet_internals'

lib_path = File.expand_path(File.join(__FILE__, '..', '..', 'lib'))
Puppet[:libdir] = lib_path

provider = Puppet::Type.type(:service).provider(:supervisor)


class Puppet::Type::Service::ProviderSupervisor
  attr_accessor :mocked_output

  def initialize resource
    super
    @mocked_output = {}
  end

  def supervisorctl(command, name=nil)
    @mocked_output[command]
  end
end


describe provider do
  context "with process group" do
    let (:resource) {
      Puppet::Type.type(:service).hash2resource({:name => 'some-program:*'})
    }
    describe "status" do
      it "should return true if all processes are RUNNING" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 RUNNING\n"
        p.status.should == :true
      end

      it "should return false if some processes are STOPPED" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 STOPPED\n"
        p.status.should == :false
      end

      it "should return false if some processes are STARTING" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 STARTING\n"
        p.status.should == :false
      end
    end
  end

  context "with a single process" do
    let (:resource) {
      Puppet::Type.type(:service).hash2resource({:name => 'some-program'})
    }
    describe "status" do
      it "should return true if the process is running" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program RUNNING'
        p.status.should == :true
      end

      it "should return false if the process is STOPPED" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program STOPPED'
        p.status.should == :false
      end

      it "should return false if the process is not found" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-other-program RUNNING'
        p.status.should == :false
      end
      it "should return false if no processes are found" do
        p = provider.new(resource)
        p.mocked_output[:status] = ''
        p.status.should == :false
      end
    end
  end
end
