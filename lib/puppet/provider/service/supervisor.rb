# Manage services using Supervisor.  Start/stop uses /sbin/service and enable/disable uses chkconfig

Puppet::Type.type(:service).provide :supervisor, :parent => :base do

  desc "Supervisor: A daemontools-like service monitor written in python"

  commands :supervisorctl => "/usr/bin/supervisorctl"

  def name_without_prefix
    @resource[:name].gsub(/^supervisor::/, '')
  end

  def group_or_process_name
    name_without_prefix
  end

  def supervisorctl_arg
    name_without_prefix + ':*'
  end

  def program_name
    @resource[:name].gsub(/^supervisor::/, '')
  end

  # Returns all processes in a structured format
  #
  # Result:
  #   [ ...,
  #     #<MatchData "foo:abc RUNNING" group_name:"foo" process_name:"abc" program_name:"abc" program_num:nil state:"RUNNING">,
  #     #<MatchData "shop-staging-send_mail:shop-staging-send_mail_00 RUNNING" group_name:"shop-staging-send_mail" process_name:"shop-staging-send_mail_00" program_name:"shop-staging-send_mail" program_num:"00" state:"RUNNING">,
  #     #<MatchData "shop-staging-send_mail:shop-staging-send_mail_01 RUNNING" group_name:"shop-staging-send_mail" process_name:"shop-staging-send_mail_01" program_name:"shop-staging-send_mail" program_num:"01" state:"RUNNING">,
  #   ... ]
  #
  # Usage:
  #   processes[:process_name]
  #
  def processes
    output = supervisorctl(:status)

    # Capture groups don't work in Ruby 1.8
    #output.lines.map { |line| line.match /^((?<group_name>.+?):)?(?<process_name>(?<program_name>.+?)(_(?<program_num>\d{2}))?) +(?<state>\w+)/ }.reject(&:nil?)

    result = output.lines.map { |line|
      line.match /^((.+?):)?((.+?)(_(\d+))?) +(\w+)/
      { :group_name => $2, :process_name => $3, :program_name => $4, :program_num => $6, :state => $7 }
    }
    result.reject(&:nil?)
  end

  def supervisorctl_args
    processes = processes().select { |process| process[:program_name] == self.program_name }
    args = processes.map do |process|
      if process[:group_name] == nil || process[:group_name].empty?
        "#{process[:process_name]}"
      else
        "#{process[:group_name]}:#{process[:process_name]}"
      end
    end

    args
  end

  def status
    begin
      processes = processes().select { |process| process[:program_name] == self.group_or_process_name }
    rescue Puppet::ExecutionFailure
      return :stopped
    end

    if processes.empty?
      return :stopped
    end

    status_is_starting = processes.select { |process| process[:state] == 'STARTING' }
    unless status_is_starting.empty?
      Puppet.warning "Could not reliably determine status: #{self.group_or_process_name} is still starting"
    end

    status_not_running = processes.reject { |process| process[:state] =~ /RUNNING|STARTING/ }
    if status_not_running.empty?
      return :running
    end

    :stopped
  end

  def restart
    output = supervisorctl(:restart, supervisorctl_args)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not restart #{self.group_or_process_name}: #{output}"
    end
  end

  def start
    output = supervisorctl(:start, supervisorctl_args)

    if output.include? 'ERROR (no such process)' or output.include? 'ERROR (abnormal termination)'
      raise Puppet::Error, "Could not start #{self.group_or_process_name}: #{output}"
    end

    filtered_output = output.lines.reject {|item| item.include? "ERROR (already started)"}

    status_not_started = filtered_output.reject {|item| item =~ /started$/}
    unless status_not_started.empty?
      raise Puppet::Error, "Could not start #{self.group_or_process_name}: #{output}"
    end
  end

  def stop
    output = supervisorctl(:stop, supervisorctl_args)

    if output.include? 'ERROR (no such process)'
      raise Puppet::Error, "Could not stop #{self.group_or_process_name}: #{output}"
    end

    if output =~ /^error/
      raise Puppet::Error, "Could not stop #{self.group_or_process_name}: #{output}"
    end
  end

end
