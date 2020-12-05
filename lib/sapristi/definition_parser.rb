# frozen_string_literal: true

module Sapristi
  class DefinitionParser
    def initialize
      @monitor_manager = MonitorManager.new
      @window_manager = WindowManager.new
    end

    def parse(definition_hash)
      definition = Definition.new(definition_hash)

      normalized = definition
      validate_normalized normalized
      normalized
    end

    private

    def validate_normalized(normalized)
      monitor = normalized.monitor
      x_pos = normalized.x_position
      y_pos = normalized.y_position
      window_width = normalized.h_size
      window_height = normalized.v_size
      x_end = x_pos + window_width
      y_end = y_pos + window_height
      work_area_width = monitor['work_area_width']
      work_area_height = monitor['work_area_height']
      monitor_width = monitor['x']
      monitor_height = monitor['y']
      min_x_size = 50
      min_y_size = 50
      workspace = normalized.workspace
      workspaces_number = @window_manager.workspaces.size
      workspaces = 0..(workspaces_number - 1)
      unless (0...monitor_width).include? x_pos
        raise Error, "x=#{x_pos} is outside of monitor width dimension=0..#{monitor_width - 1}"
      end
      unless (0...monitor_height).include? y_pos
        raise Error, "y=#{y_pos} is outside of monitor height dimension=0..#{monitor_height - 1}"
      end
      if x_end >= monitor_width
        raise Error, "window x dimensions: [#{x_pos}, #{x_end}] exceeds monitor width [0..#{monitor_width - 1}]"
      end
      if y_end >= monitor_height
        raise Error, "window y dimensions: [#{y_pos}, #{y_end}] exceeds monitor height [0..#{monitor_height - 1}]"
      end
      raise Error, "window x size=#{window_width} less than #{min_x_size}" if window_width < min_x_size
      raise Error, "window y size=#{window_height} less than #{min_y_size}" if window_height < min_y_size

      raise Error, "invalid workspace=#{workspace} valid=#{workspaces}" unless workspaces.include? workspace
    end
  end
end
