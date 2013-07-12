# Manage services using Supervisor.  Start/stop uses /sbin/service and enable/disable uses chkconfig

Puppet::Type.type(:service).provide :supervisor, :parent => :base do

  desc "Supervisor: A daemontools-like service monitor written in python
  "

  commands :supervisord   => "/usr/bin/supervisord",
           :supervisorctl => "/usr/bin/supervisorctl"

  def self.instances
    # this exclude list is all from /sbin/service (5.x), but I did not exclude kudzu
    []
  end

  def enable
      output = supervisorctl(:add, @resource[:name])
  rescue Puppet::ExecutionFailure => detail
      raise Puppet::Error, "Could not enable #{self.name}: #{detail}"
  end

  def disable
    self.stopcmd
    output = supervisorctl(:remove, @resource[:name])
  rescue Puppet::ExecutionFailure
    raise Puppet::Error, "Could not disable #{self.name}: #{output}"
  end

  def status
    begin
      output = supervisorctl(:status)
    rescue Puppet::ExecutionFailure
      return :false
    end

    filtered_output = output.lines.grep /#{@resource[:name]}[ :_]/
    if filtered_output.empty?
      return :false
    end

    status_not_running = filtered_output.reject {|item| item =~ /RUNNING/}

    if status_not_running.empty?
      return :true
    end

    :false
  end

  # use hasstatus=>true when its set for the provider.
  def statuscmd
    ((@resource.provider.get(:hasstatus) == true) || (@resource[:hasstatus] == :true)) && [command(:supervisorctl), "status", @resource[:name]]
  end

  def restartcmd
    (@resource[:hasrestart] == :true) && [command(:service), "restart", @resource[:name]]
  end

  def startcmd
    [command(:service), "start", @resource[:name]]
  end

  def stopcmd
    [command(:service), "stop", @resource[:name]]
  end

end
