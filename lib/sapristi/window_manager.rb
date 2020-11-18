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
      # sleep to allow a Graceful Dead (tm) to the window process
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
      windows = @display.windows
      windows_data = windows.map(&:to_h)

      user_id = `id -u`.strip
      previous_pids = `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)

      process_pid = begin
        Process.spawn(cmd)
      rescue StandardError
        (raise Error, "Error executing process: #{$ERROR_INFO}")
      end
      puts "Launch #{cmd.split[0]}, process=#{process_pid}"
      waiter = Process.detach process_pid

      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds && waiter.alive?
        new_windows_found = @display.windows.filter { |w| !windows_data.include? w.to_h }
        																		.filter { |w| !previous_pids.include? w.pid }

        new_windows_found.each { |a| puts "  Found new window=#{a.pid}, process=#{process_pid}: #{a.title}" }
        process_window = new_windows_found.find { |window| window.pid.eql? process_pid }

        break if process_window

        sleep 0.5
      end

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      if process_window.nil?
        Process.kill 'KILL', process_pid
        # sleep 1 # XLIB error for op code
        raise Error, "Error executing process, it didn't open a window"
      end

      puts "Found window title=#{process_window.title} for process=#{process_pid}!"
      process_window
    end

    GRAVITY = 0
    def resize(window, width, height)
      x = window.geometry[0]
      y = window.geometry[1]

      @display.action_window(window.id, :move_resize, GRAVITY, x, y, width, height)
    end

    def move(window, x, y)
      width = window.geometry[2]
      height = window.geometry[3]

      @display.action_window(window.id, :move_resize, GRAVITY, x, y, width, height)
    end
  end
end
