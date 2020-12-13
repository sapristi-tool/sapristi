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

      process_window = window_detector.detect_window_for_process(waiter, timeout_in_seconds)

      kill waiter unless process_window

      process_window
    end

    GRAVITY = 0
    TIME_TO_APPLY_DIMENSIONS = 0.5
    def move_resize(window, x_position, y_position, width, height)
      call_move_resize(window, [x_position, y_position, width, height])
    end

    def resize(window, width, height)
      x_position, y_position = @display.windows(id: window.id).first.geometry
      call_move_resize(window, [x_position, y_position, width, height])
    end

    def move(window, x_position, y_position)
      width, height = @display.windows(id: window.id).first.geometry[2..3]
      call_move_resize(window, [x_position, y_position, width, height])
    end

    def workspaces
      @display.desktops
    end

    def find_workspace_or_current(id)
      return workspaces.find(&:current).id unless id

      return id if workspace?(id)

      available = 0..(workspaces.size - 1)
      raise Error, "invalid workspace=#{id} valid=#{available}" unless available.include? id
    end

    private

    def workspace?(id)
      workspaces.find { |workspace| workspace.id.eql? id }
    end

    def kill(waiter)
      Process.kill 'KILL', waiter.pid
      # sleep 1 # XLIB error for op code
      raise Error, 'Error executing process, it didn\'t open a window'
    end

    def call_move_resize(window, geometry)
      @display.action_window(window.id, :move_resize, GRAVITY, *geometry)
      sleep TIME_TO_APPLY_DIMENSIONS
      check_expected_geometry window, geometry
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

    # private_class_method :text_diff
  end
end
