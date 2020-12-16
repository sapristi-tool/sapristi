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

    def move_resize(window, x_position, y_position, width, height)
      call_move_resize(window, [x_position, y_position, width, height])
    end

    def resize(window, width, height)
      actual_window = @display.windows(id: window.id).first
      x_position, y_position = (actual_window.exterior_frame || actual_window.geometry)[0..1]
      call_move_resize(window, [x_position, y_position, width, height])
    end

    def move(window, x_position, y_position)
      actual_window = @display.windows(id: window.id).first
      width, height = (actual_window.exterior_frame || actual_window.geometry)[2..3]
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

    def call_move_resize(window, requested)
      geometry = requested.clone
      left, right, top, bottom = window.frame_extents || [0, 0, 0, 0]
      geometry[2] -= left + right
      geometry[3] -= top + bottom

      @display.move_resize(window, geometry)

      check_expected_geometry window, requested
    end

    LABELS = %w[x y width heigth].freeze

    def check_expected_geometry(window, expected)
      actual_window = @display.windows(id: window.id).first
      actual = actual_window.exterior_frame || actual_window.geometry

      unless actual.eql? expected
        ::Sapristi.logger.warn "Geometry mismatch #{WindowManager.text_diff(actual, expected)}, requested=#{expected}, window=#{window.title}"
      end
    end

    def self.text_diff(actual, expected)
      diffs = 4.times.filter { |index| !expected[index].eql? actual[index] }
      diffs.map { |diff_index| "#{LABELS[diff_index]}: expected=#{expected[diff_index]}, actual=#{actual[diff_index]}" }.join(', ')
    end
  end
end
