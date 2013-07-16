# Manage services using Supervisor.  Start/stop uses /sbin/service and enable/disable uses chkconfig

Puppet::Type.type(:service).provide :supervisor, :parent => :base do

  desc "Supervisor: A daemontools-like service monitor written in python"

  commands :supervisorctl => "/usr/bin/supervisorctl"

  def program_name
    @resource[:name].split(':')[0]
  end

  def process_name
    @resource[:name]
  end

  def status
    begin
      output = supervisorctl(:status)
    rescue Puppet::ExecutionFailure
      return :stopped
    end

    filtered_output = output.lines.grep /#{self.program_name}[ :]/
    if filtered_output.empty?
      return :stopped
    end

    status_is_starting = filtered_output.grep(/STARTING/)
    unless status_is_starting.empty?
      Puppet.warning "Could not reliably determine status: process #{self.process_name} is still starting"
    end

    status_not_running = filtered_output.reject {|item| item =~ /RUNNING|STARTING/}
    if status_not_running.empty?
      return :running
    end

    :stopped
  end

  def restart
    output = supervisorctl(:restart, self.process_name)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not restart #{self.process_name}: #{output}"
    end
  end

  def start
    output = supervisorctl(:start, self.process_name)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not start #{self.process_name}: #{output}"
    end

    filtered_output = output.lines.reject {|item| item.include? "ERROR (already started)"}

    status_not_started = filtered_output.reject {|item| item =~ /started$/}
    unless status_not_started.empty?
      raise Puppet::Error, "Could not start #{self.process_name}: #{output}"
    end
  end

  def stop
    output = supervisorctl(:stop, self.process_name)

    if output.include? 'ERROR (no such process)'
      raise Puppet::Error, "Could not stop #{self.process_name}: #{output}"
    end

    if output =~ /^error/
      raise Puppet::Error, "Could not stop #{self.process_name}: #{output}"
    end
  end

end
