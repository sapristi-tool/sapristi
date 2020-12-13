# frozen_string_literal: true

module Sapristi
  class Definition
    TRANSLATIONS = {
      'H-size' => 'work_area_width', 'V-size' => 'work_area_height',
      'X-position' => 'work_area_width', 'Y-position' => 'work_area_height'
    }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace]).freeze

    def initialize(definition_hash)
      @raw_definition = definition_hash.clone
      validate_raw

      @monitor = MonitorManager.new.get_monitor_or_main definition_hash['Monitor']
      normalize_variables
      @workspace ||= WindowManager.new.workspaces.find(&:current).id # FIXME: find_or_current
    end

    attr_reader :raw_definition, :monitor, :x_position, :y_position, :v_size, :h_size, :workspace, :command, :title

    private

    def normalize_variables
      %w[Title Command X-position Y-position H-size V-size Workspace].each do |variable|
        raw = @raw_definition[variable]

        normalized_value = AttributeNormalizer.new(variable, raw, @monitor).normalize
        self[variable] = normalized_value
      end
    end

    def []=(key, value)
      instance_variable_set "@#{Definition.normalize_key key}".to_sym, value
    end

    def self.normalize_key(key)
      key.downcase.gsub(/-/, '_')
    end

    def validate_raw
      definition = @raw_definition
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil

      raise Error, 'Invalid monitor=-1' if definition['Monitor']&.to_i&.negative?
    end
  end
end
