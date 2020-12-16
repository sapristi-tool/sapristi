# frozen_string_literal: true

module Sapristi
  class NewProcessWindowDetector
    def initialize
      @display = WMCtrl.display
      @process_manager = Linux::ProcessManager.new
    end

    def detect_window_for_process(command, timeout_in_seconds = 30)
      save_pids_and_windows

      process_window = wait_for_window(command, timeout_in_seconds)

      if process_window
        ::Sapristi.logger.info "  Found window title=#{process_window.title} for process=#{process_window.pid}!"
      end

      process_window
    end

    private

    attr_reader :previous_windows_ids, :previous_pids, :process_manager

    def save_pids_and_windows
      @previous_windows_ids = @display.windows.map { |window| window[:id] }
      @previous_pids = process_manager.class.user_pids
    end

    def wait_for_window(command, timeout_in_seconds)
      program = command.split[0]
      waiter = process_manager.execute_and_detach command

      window = discover_window(waiter, program, timeout_in_seconds)
      return window if window

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      process_manager.kill waiter
    end

    def discover_window(waiter, program, timeout_in_seconds)
      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds # && waiter.alive?
        process_window = detect_new_windows.find do |window|
          window_for_waiter?(waiter, window) || window_for_command?(waiter, window, program)
        end

        return process_window if process_window

        sleep 0.5
      end
    end

    def window_for_waiter?(waiter, window)
      waiter.alive? && window.pid.eql?(waiter.pid)
    end

    def window_for_command?(waiter, window, program)
      !waiter.alive? && process_manager.cmd_for_pid(window.pid).start_with?(program)
    end

    def detect_new_windows
      new_windows = @display.windows.filter { |window| new_window?(window) }

      new_windows.each { |window| ::Sapristi.logger.debug "  Found new window=#{window.pid}: #{window.title}" }
    end

    def new_window?(window)
      !previous_windows_ids.include?(window.id)
    end
  end
end
