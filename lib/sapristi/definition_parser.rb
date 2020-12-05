# frozen_string_literal: true

module Sapristi
  class DefinitionParser
    def initialize
      @monitor_manager = MonitorManager.new
      @window_manager = WindowManager.new
    end

    def parse(definition_hash)
      definition = Definition.new(definition_hash)

      validate definition
      definition
    end

    private

    def validate(definition)
      validate_monitor(definition)
      validate_window_min_size(definition)
      validate_workspace(definition)
    end

    def validate_monitor(definition)
      monitor = definition.monitor
      monitor_width = monitor['x']
      monitor_height = monitor['y']

      validate_monitor_dimensions(definition, monitor_width, monitor_height)
      validate_work_area(definition, monitor_width, monitor_height)
    end

    def validate_monitor_dimensions(normalized, monitor_width, monitor_height)
      x_pos = normalized.x_position
      y_pos = normalized.y_position
      unless (0...monitor_width).include? x_pos
        raise Error, "x=#{x_pos} is outside of monitor width dimension=0..#{monitor_width - 1}"
      end
      unless (0...monitor_height).include? y_pos
        raise Error, "y=#{y_pos} is outside of monitor height dimension=0..#{monitor_height - 1}"
      end
    end

    def validate_work_area(normalized, monitor_width, monitor_height)
      x_pos = normalized.x_position
      y_pos = normalized.y_position
      x_end = x_pos + normalized.h_size
      y_end = y_pos + normalized.v_size
      if x_end >= monitor_width
        raise Error, "window x dimensions: [#{x_pos}, #{x_end}] exceeds monitor width [0..#{monitor_width - 1}]"
      end
      if y_end >= monitor_height
        raise Error, "window y dimensions: [#{y_pos}, #{y_end}] exceeds monitor height [0..#{monitor_height - 1}]"
      end
    end

    MIN_X_SIZE = 50
    MIN_Y_SIZE = 50
    def validate_window_min_size(normalized)
      window_width = normalized.h_size
      window_height = normalized.v_size
      raise Error, "window x size=#{window_width} less than #{MIN_X_SIZE}" if window_width < MIN_X_SIZE
      raise Error, "window y size=#{window_height} less than #{MIN_Y_SIZE}" if window_height < MIN_Y_SIZE
    end

    def validate_workspace(definition)
      workspace = definition.workspace
      raise Error, "invalid workspace=#{workspace} valid=#{workspaces}" unless workspaces.include? workspace
    end

    def workspaces
      workspaces_number = @window_manager.workspaces.size
      0..(workspaces_number - 1)
    end
  end
end
