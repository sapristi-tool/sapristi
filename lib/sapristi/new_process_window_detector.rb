# frozen_string_literal: true

module Sapristi
  class NewProcessWindowDetector
    def initialize
      @display = WMCtrl.display
      @previous_windows_ids = @display.windows.map { |window| window[:id] }
      @previous_pids = NewProcessWindowDetector.user_pids
    end

    attr_reader :previous_windows_ids, :previous_pids

    def detect_window_for_process(waiter, timeout_in_seconds)
      process_window = wait_for_window(waiter, timeout_in_seconds)

      ::Sapristi.logger.info "  Found window title=#{process_window.title} for process=#{waiter.pid}!" if process_window

      process_window
    end

    private

    def wait_for_window(waiter, timeout_in_seconds)
      command = 'gedit'
      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds # && waiter.alive?
        process_window = detect_new_windows.find { |window| window_for_waiter?(waiter, window) || window_for_command(waiter, window, command) }

        return process_window if process_window

        sleep 0.5
      end
      raise Error, 'Error executing process, is dead' unless waiter.alive?
    end

    def window_for_waiter?(waiter, window)
      waiter.alive? && window.pid.eql?(waiter.pid)
    end

    def window_for_command(waiter, window, command)
      !waiter.alive? && cmd_for_pid(window.pid).start_with?(command)
    end

    def self.user_pids
      user_id = `id -u`.strip
      `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
    end

    def detect_new_windows
      new_windows = @display.windows.filter { |window| new_window?(window) }

      new_windows.each { |window| ::Sapristi.logger.debug "  Found new window=#{window.pid}: #{window.title}" }
    end

    def new_window?(window)
      !previous_windows_ids.include?(window.id)
    end

    def cmd_for_pid(pid)
      cmd = "ps -o cmd -p #{pid}"
      line = `#{cmd}`.split("\n")[1]
      raise Error, "No process found pid=#{pid}" unless line

      line
    end
  end
end
