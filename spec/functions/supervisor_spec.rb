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
      it "should return running if all processes are RUNNING" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 RUNNING\n"
        p.status.should == :running
      end

      it "should return stopped if some processes are STOPPED" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 STOPPED\n"
        p.status.should == :stopped
      end

      it "should return stopped if some processes are STARTING" do
        p = provider.new(resource)
        p.mocked_output[:status] = "some-program:some-program_9000 RUNNING\nsome-program:some-program_9000 STARTING\n"
        p.status.should == :stopped
      end
    end
    describe "start" do
      it "should succeed if all processes are already started (no output from supervisorctl)" do
        p = provider.new(resource)
        p.mocked_output[:start] = ''
        p.start
      end
      it "should succeed if all processes are started" do
        p = provider.new(resource)
        p.mocked_output[:start] = <<-EOF
          some-program:some-program_9000: started
          some-program:some-program_9001: started
        EOF
        p.start
      end
      it "should fail if not all processes are started" do
        p = provider.new(resource)
        p.mocked_output[:start] = <<-EOF
          some-program:some-program_9000: started
          some-program:some-program_9001: ERROR (abnormal termination)
        EOF
        expect {
          p.start
        }.to raise_error(Puppet::Error, /Could not start Service.some-program/)
      end
      it "should fail if output is unexpected" do
        p = provider.new(resource)
        p.mocked_output[:start] = <<-EOF
          and what do you think about king prawn?
        EOF
        expect {
          p.start
        }.to raise_error(Puppet::Error, /Could not start Service.some-program/)
      end
    end
    describe "restart" do
      it "should succeed if all processes are started and stopped" do
        p = provider.new(resource)
        p.mocked_output[:start] = <<-EOF
          some-program:some-program_9000: stopped
          some-program:some-program_9001: stopped
          some-program:some-program_9000: started
          some-program:some-program_9001: started
        EOF
        p.restart
      end
    end
  end

  context "with a single process" do
    let (:resource) {
      Puppet::Type.type(:service).hash2resource({:name => 'some-program'})
    }
    describe "status" do
      it "should return running if the process is running" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program RUNNING'
        p.status.should == :running
      end

      it "should return stopped if the process is STOPPED" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program STOPPED'
        p.status.should == :stopped
      end

      it "should return stopped if the process is not found" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-other-program RUNNING'
        p.status.should == :stopped
      end
      it "should return stopped if no processes are found" do
        p = provider.new(resource)
        p.mocked_output[:status] = ''
        p.status.should == :stopped
      end
    end
    describe "start" do
      it "should succeed if process already started" do
        p = provider.new(resource)
        p.mocked_output[:start] = 'some-program: ERROR (already started)'
        p.start
      end

      it "should fail if process is not found" do
        p = provider.new(resource)
        p.mocked_output[:start] = 'some-program: ERROR (no such process)'
        expect {
          p.start
        }.to raise_error(Puppet::Error, /Could not start Service.some-program/)
      end
    end
  end
end
