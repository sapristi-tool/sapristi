# frozen_string_literal: true

module Sapristi
  class Definition
    TRANSLATIONS = {
      'H-size' => 'work_area_width', 'V-size' => 'work_area_height',
      'X-position' => 'work_area_width', 'Y-position' => 'work_area_height'
    }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace]).freeze

    def initialize(definition_hash)
      validate_raw definition_hash
      @raw_definition = definition_hash.clone

      @monitor = MonitorManager.new.get_monitor_or_main definition_hash['Monitor']
      @workspace = WindowManager.new.find_workspace_or_current definition_hash['Workspace']&.to_i
      normalize_variables
    end

    attr_reader :raw_definition, :monitor, :x_position, :y_position, :v_size, :h_size, :workspace, :command, :title

    private

    def normalize_variables
      %w[Title Command X-position Y-position H-size V-size].each do |key|
        name = key.downcase.gsub(/-/, '_')
        value = AttributeNormalizer.new(key, @raw_definition[key], @monitor).normalize
        instance_variable_set "@#{name}".to_sym, value
      end
    end

    def validate_raw(definition)
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil

      raise Error, 'Invalid monitor=-1' if definition['Monitor']&.to_i&.negative?
    end
  end
end
