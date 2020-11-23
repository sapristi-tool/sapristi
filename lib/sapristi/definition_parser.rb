# frozen_string_literal: true

module Sapristi
  class DefinitionParser
    TRANSLATIONS = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace Monitor]).freeze
    NORMALIZED_FIELD_SUFFIX = '_raw'

    def initialize
      @monitor_manager = MonitorManager.new
      @window_manager = WindowManager.new
    end

    def parse(definition)
      validate_raw(definition)

      monitor = @monitor_manager.get_monitor definition['Monitor']

      normalized = normalize definition, monitor
      validate_normalized normalized, monitor
      normalized
    end

    private

    def normalize(definition, monitor)
      normalized = definition.to_h.keys.each_with_object({}) do |key, memo|
        normalize_key(key, definition[key], memo, monitor)
      end

      NUMERIC_FIELDS
        .filter { |field| normalized[field] }
        .each { |field| normalized[field] = normalized[field].to_i }
      normalized['Workspace'] ||= @window_manager.workspaces.find(&:current).id

      normalized
    end

    def validate_raw(definition)
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil

      raise Error, 'Invalid monitor=-1' if definition['Monitor']&.to_i&.negative?
    end

    def validate_normalized(normalized, monitor)
      x_pos = normalized['X-position']
      y_pos = normalized['Y-position']
      window_width = normalized['H-size']
      window_height = normalized['V-size']
      x_end = x_pos + window_width
      y_end = y_pos + window_height
      monitor_width = monitor['x']
      monitor_height = monitor['y']
      min_x_size = 50
      min_y_size = 50
      workspace = normalized['Workspace']
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

    def normalize_key(key, raw, memo, monitor)
      is_percentage = raw&.to_s&.match(/^([0-9]+)%$/)

      if is_percentage
        memo[key] = apply_percentage(key, raw, monitor)
        memo[key + NORMALIZED_FIELD_SUFFIX] = raw
      elsif raw.to_s.include?('%')
        raise Error, "key=#{key}, invalid percentage=#{raw}"
      else
        memo[key] = raw
      end
    end

    def apply_percentage(key, raw, monitor)
      validate_percentage_field(key, raw)

      value = raw.to_s.match(/^([0-9]+)%$/)[1].to_i
      percentage = value / 100.0
      monitor_absolute = monitor[TRANSLATIONS[key]]

      (monitor_absolute * percentage).to_i
    end

    def validate_percentage_field(key, raw)
      translated_key = TRANSLATIONS[key]
      unless translated_key
        raise "#{key}=#{raw}, using percentage in invalid field, valid=#{TRANSLATIONS.keys.join(', ')}"
      end

      value = raw.to_s.match(/^([0-9]+)%$/)[1].to_i
      raise Error, "#{key} percentage is invalid=#{raw}, valid=5%-100%" if value < 5 || value > 100
    end
  end
end
