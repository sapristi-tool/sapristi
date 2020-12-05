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
      window_detector = NewProcessWindowDetector.new

      waiter = execute_and_detach cmd
      pid = waiter.pid

      process_window = window_detector.detect_window_for_process(waiter, timeout_in_seconds)

      if process_window.nil?
        Process.kill 'KILL', pid
        # sleep 1 # XLIB error for op code
        raise Error, "Error executing process, it didn't open a window"
      end

      ::Sapristi.logger.info "  Found window title=#{process_window.title} for process=#{pid}!"
      process_window
    end

    GRAVITY = 0
    TIME_TO_APPLY_DIMENSIONS = 0.5
    def move_resize(window, x_position, y_position, width, height)
      call_move_resize(window, x_position, y_position, width, height)
    end

    def resize(window, width, height)
      x_position, y_position = @display.windows(id: window.id).first.geometry
      call_move_resize(window, x_position, y_position, width, height)
    end

    def move(window, x_position, y_position)
      width, height = @display.windows(id: window.id).first.geometry[2..3]
      call_move_resize(window, x_position, y_position, width, height)
    end

    def workspaces
      @display.desktops
    end

    private

    def call_move_resize(window, x_position, y_position, width, height)
      @display.action_window(window.id, :move_resize, GRAVITY, x_position, y_position, width, height)
      sleep TIME_TO_APPLY_DIMENSIONS
      expected = [x_position, y_position, width, height]
      check_expected_geometry window, expected
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

    LABELS = %w[x y width heigth].freeze

    def check_expected_geometry(window, expected)
      actual = @display.windows(id: window.id).first.geometry

      unless actual.eql? expected
        ::Sapristi.logger.warn "Geometry mismatch #{WindowManager.text_diff(actual, expected)}, requested=#{expected}"
      end
    end

    def self.text_diff(actual, expected)
      diffs = 4.times.filter { |index| !expected[index].eql? actual[index] }
      diffs.map { |diff_index| "#{LABELS[diff_index]}: expected=#{expected[diff_index]}, actual=#{actual[diff_index]}" }.join(', ')
    end

    private_class_method :text_diff
  end

  class NewProcessWindowDetector
    def initialize
      @display = WMCtrl.display
      @previous_windows_ids = @display.windows.map { |window| window[:id] }
      @previous_pids = NewProcessWindowDetector.user_pids
    end

    attr_reader :previous_windows_ids, :previous_pids

    def detect_window_for_process(waiter, timeout_in_seconds)
      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds && waiter.alive?
        process_window = detect_new_windows.find { |window| window.pid.eql? waiter.pid }

        break if process_window

        sleep 0.5
      end

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      process_window
    end

    private

    def self.user_pids
      user_id = `id -u`.strip
      `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
    end

    def detect_new_windows
      new_windows = @display.windows.filter { |window| new_window?(window) }

      new_windows.each { |window| ::Sapristi.logger.debug "  Found new window=#{window.pid}: #{window.title}" }
    end

    def new_window?(window)
      !previous_pids.include?(window.pid) && !previous_windows_ids.include?(window.id)
    end
  end
end
