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

  context "with no processes configured" do
    let (:resource) {
      Puppet::Type.type(:service).hash2resource({:name => 'some-program'})
    }

    describe "status" do
      it "should return stopped if status produces no output" do
        p = provider.new(resource)
        p.mocked_output[:status] = ''
        p.status.should == :stopped
      end
    end
  end

  context "with process group" do
    let (:resource) {
      Puppet::Type.type(:service).hash2resource({:name => 'some-program:*'})
    }

    describe "status" do
      it "should return running if the processes are running" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 RUNNING
          some-program:some-program_9001 RUNNING
        EOF
        p.status.should == :running
      end

      it "should return running if some processes are starting" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 STARTING
          some-program:some-program_9001 RUNNING
        EOF
        p.status.should == :running
      end

      it "should return stopped if the processes are stopped" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 STOPPED
          some-program:some-program_9001 STOPPED
        EOF
        p.status.should == :stopped
      end

      it "should return stopped if the processes are stopped" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 STOPPED
          some-program:some-program_9001 STOPPED
        EOF
        p.status.should == :stopped
      end

      it "should return stopped if some processes are stopped and some are running" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 STOPPED
          some-program:some-program_9001 RUNNING
          some-program:some-program_9002 STOPPED
        EOF
        p.status.should == :stopped
      end

      # This one is suspicious: should we really be that optimistic
      # and hope that STARTING will be RUNNING soon?
      # We could try sleeping $startsecs after restart. After that the state is deterministic.
      # For now we just issue a warning.
      it "should return running if the processes are starting" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 STARTING
          some-program:some-program_9001 STARTING
        EOF
        p.status.should == :running
      end

      it "should return stopped if the processes are not found" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-other-program:some-other-program_9000 RUNNING
          some-other-program:some-other-program_9001 RUNNING
        EOF
        p.status.should == :stopped
      end

      it "should return stopped if some processes are fatal" do
        p = provider.new(resource)
        p.mocked_output[:status] = <<-EOF
          some-program:some-program_9000 FATAL
          some-program:some-program_9001 RUNNING
        EOF
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
        p.mocked_output[:restart] = <<-EOF
          some-program:some-program_9000: stopped
          some-program:some-program_9001: stopped
          some-program:some-program_9000: started
          some-program:some-program_9001: started
        EOF
        p.restart
      end

      it "should fail if not all processes are started and stopped" do
        p = provider.new(resource)
        p.mocked_output[:restart] = <<-EOF
          some-program:some-program_9000: stopped
          some-program:some-program_9001: stopped
          some-program:some-program_9001: started
          some-program:some-program_9000: ERROR (abnormal termination)
        EOF
        expect {
          p.restart
        }.to raise_error(Puppet::Error, /Could not restart Service.some-program/)
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

      it "should return stopped if the process is stopped" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program STOPPED'
        p.status.should == :stopped
      end

      # This one is suspicious: should we really be that optimistic
      # and hope that STARTING will be RUNNING soon?
      # We could try sleeping $startsecs after restart. After that the state is deterministic.
      # For now we just issue a warning.
      it "should return running if the process is starting" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program STARTING'
        p.status.should == :running
      end

      it "should return stopped if the process is not found" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-other-program RUNNING'
        p.status.should == :stopped
      end

      it "should return stopped if the process is fatal" do
        p = provider.new(resource)
        p.mocked_output[:status] = 'some-program FATAL'
        p.status.should == :stopped
      end
    end

    describe "start" do

      it "should start the process if it is stopped" do
        p = provider.new(resource)
        p.mocked_output[:start] = 'some-program: started'
        p.start
      end

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
        }.to raise_error(Puppet::Error, %r{Could not start Service/some-program})
      end
    end

    describe "stop" do

      it "should stop the process if it is running" do
        p = provider.new(resource)
        p.mocked_output[:stop] = 'some-program: stopped'
        p.stop
      end

      it "should succeed if process already stopped" do
        p = provider.new(resource)
        p.mocked_output[:stop] = 'some-program: ERROR (not running)'
        p.stop
      end

      it "should fail if the process name is not found" do
        p = provider.new(resource)
        p.mocked_output[:stop] = 'some-program: ERROR (no such process)'
        expect {
          p.stop
        }.to raise_error(Puppet::Error, %r{Could not start Service/some-program})
      end
    end

    describe "restart" do

      it "should succeed if the process is stopped" do
        p = provider.new(resource)
        p.mocked_output[:restart] = <<-EOF
          some-program: ERROR (not running)
          some-program: started
        EOF
        p.restart
      end

      it "should succeed if the process is running" do
        p = provider.new(resource)
        p.mocked_output[:restart] = <<-EOF
          some-program: stopped
          some-program: started
        EOF
        p.restart
      end

      it "should fail if the process could not be started" do

        p = provider.new(resource)
        p.mocked_output[:restart] = <<-EOF
          some-program: stopped
          some-program: ERROR (abnormal termination)
        EOF
        expect {
          p.restart
        }.to raise_error(Puppet::Error, %r{Could not restart Service/some-program})
      end

    end
  end
end
