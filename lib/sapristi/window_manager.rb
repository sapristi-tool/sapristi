# frozen_string_literal: true

module Sapristi
  class WindowManager
    def initialize
      @display = Linux::WindowManager.new
    end

    def windows
      @display.windows
    end

    def close(window)
      @display.close(window)
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
      @display.workspaces
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
      @display.move_resize(window, geometry)

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
  end
end
