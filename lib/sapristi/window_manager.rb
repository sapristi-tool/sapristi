# frozen_string_literal: true

require 'wmctrl'

module Sapristi
  class WindowManager
    def initialize
      @display = WMCtrl.display
    end

    def windows
      @display.windows
    end

    def close(window)
      @display.action_window(window.id, :close)

      #
      # sleep to allow a Graceful Dead to the window process
      #
      # X Error of failed request:  BadWindow (invalid Window parameter)
      #   Major opcode of failed request:  20 (X_GetProperty)
      #   Resource id in failed request:  0x2200008
      #   Serial number of failed request:  1095
      #   Current serial number in output stream:  1095
      sleep 1
    end

    def find_window(title_regex)
      @display.windows title: title_regex
    end

    def launch(cmd, timeout_in_seconds = 30)
      previous_windows = @display.windows
      previous_pids = user_pids

      waiter = execute_and_detach cmd

      process_window = detect_window_for_process(waiter, previous_windows, previous_pids, timeout_in_seconds)

      if process_window.nil?
        Process.kill 'KILL', waiter.pid
        # sleep 1 # XLIB error for op code
        raise Error, "Error executing process, it didn't open a window"
      end

      ::Sapristi.logger.info "  Found window title=#{process_window.title} for process=#{waiter.pid}!"
      process_window
    end

    GRAVITY = 0
    def resize(window, width, height)
      x = window.geometry[0]
      y = window.geometry[1]

      @display.action_window(window.id, :move_resize, GRAVITY, x, y, width, height)
    end

    def move(window, x_position, y_position)
      width = window.geometry[2]
      height = window.geometry[3]

      @display.action_window(window.id, :move_resize, GRAVITY, x_position, y_position, width, height)
    end

    private

    def user_pids
      user_id = `id -u`.strip
      `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
    end

    def execute_and_detach(cmd)
      process_pid = begin
        Process.spawn(cmd)
      rescue StandardError
        raise Error, "Error executing process: #{$ERROR_INFO}"
      end
      ::Sapristi.logger.info "Launch #{cmd.split[0]}, process=#{process_pid}"
      Process.detach process_pid
    end

    def detect_window_for_process(waiter, previous_windows, previous_pids, timeout_in_seconds)
      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds && waiter.alive?
        process_window = detect_new_windows(previous_windows, previous_pids).find { |w| w.pid.eql? waiter.pid }

        break if process_window

        sleep 0.5
      end

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      process_window
    end

    def detect_new_windows(previous_windows, previous_pids)
      new_windows_found = @display.windows.filter do |w|
        !previous_pids.include?(w.pid) && previous_windows.none? { |old| old.id.eql? w.id }
      end

      new_windows_found.each { |w| ::Sapristi.logger.debug "  Found new window=#{w.pid}: #{w.title}" }
    end
  end
end
