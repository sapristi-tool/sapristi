# frozen_string_literal: true

module Sapristi
  class NewProcessWindowDetector
    def initialize
      @display = OSFactory.new.window_manager
      @process_manager = OSFactory.new.process_manager
      @log = ::Sapristi.logger
    end

    def detect_window_for_process(command, title, timeout_in_seconds = 30)
      save_pids_and_windows

      process_window = wait_for_window(command, title, timeout_in_seconds)

      if process_window
        ::Sapristi.logger.info "  Found window title=#{process_window.title} for process=#{process_window.pid}!"
      end

      process_window
    end

    private

    attr_reader :previous_windows_ids, :previous_pids, :process_manager, :log

    def save_pids_and_windows
      @previous_windows_ids = @display.windows.map { |window| window[:id] }
      @previous_pids = process_manager.user_pids
    end

    def wait_for_window(command, title, timeout_in_seconds)
      program = command.split[0]
      waiter = process_manager.execute_and_detach command, '/tmp/sapristi.stdout', '/tmp/sapristi.stderr'

      window = discover_window(waiter, program, title, timeout_in_seconds)
      return window if window

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      process_manager.kill waiter
    end

    # This method smells of :reek:DuplicateMethodCall
    # This method smells of :reek:LongParameterList
    def discover_window(waiter, program, title, timeout_in_seconds)
      start_time = Time.now

      while Time.now - start_time < timeout_in_seconds # && waiter.alive?
        new_window = detect_new_windows.find { |window| window_for?(waiter, program, title, window) }

        return new_window if new_window && !splash?(new_window)

        sleep 0.2
      end
    end

    # This method smells of :reek:DuplicateMethodCall
    # This method smells of :reek:FeatureEnvy
    # This method smells of :reek:LongParameterList
    # This method smells of :reek:TooManyStatements
    def window_for?(waiter, program, title, window)
      window_pgroup = Process.getpgid(window.pid)
      log.debug "Found new window: pid=#{window.pid}, ppid=#{window_pgroup}, id=#{window.id}, title=#{window.title}"
      if window_for_waiter?(waiter, window)
        log.debug "Found window by pid=#{waiter.pid}, id=#{window.id}, title=#{window.title}"
        true
      elsif window_for_process_group?(window)
        log.debug "Found window by process group=#{Process.getpgid(window.pid)}, id=#{window.id}, title=#{window.title}"
        true
      elsif window_for_command?(window, program)
        log.debug "Found window by program=#{program}, id=#{window.id}, title=#{window.title}"
        true
      elsif window_for_title?(window, title)
        log.debug "Found window by title=#{title}, id=#{window.id}, title=#{window.title}"
        true
      else
        log.warn "We can not be sure window '#{window.title}' with pid=#{window.pid} is related to program=#{program}, pid=#{waiter.pid}, status=#{waiter.status || 'dead'}"
        false
      end
    end

    def window_for_title?(window, title)
      /#{title}/i.match(window.title)
    end

    def window_for_waiter?(waiter, window)
      window.pid.eql?(waiter.pid)
    end

    def window_for_process_group?(window)
      Process.getpgid(window.pid).eql?(Process.getpgrp)
    end

    def window_for_command?(window, program)
      process_manager.cmd_for_pid(window.pid).start_with?(program)
    end

    def detect_new_windows
      new_windows = @display.windows.filter { |window| new_window?(window) }

      new_windows.each { |window| ::Sapristi.logger.debug "  Found new window=#{window.pid}: #{window.title}" }
    end

    def new_window?(window)
      !previous_windows_ids.include?(window.id)
    end

    def splash?(window)
      skip_taskbar?(window) || skip_pager?(window)
    end

    def skip_taskbar?(window)
      window.state.include? '_NET_WM_STATE_SKIP_TASKBAR'
    end

    def skip_pager?(window)
      window.state.include? '_NET_WM_STATE_SKIP_PAGER'
    end
  end
end
