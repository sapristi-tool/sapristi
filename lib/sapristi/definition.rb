# frozen_string_literal: true

module Sapristi
  class Definition
    TRANSLATIONS = {
      'Width' => 'work_area_width', 'Height' => 'work_area_height',
      'X' => 'work_area_width', 'Y' => 'work_area_height'
    }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace]).freeze

    def initialize(definition_hash)
      validate_raw definition_hash
      @raw_definition = definition_hash.to_h.clone

      @monitor = MonitorManager.new.get_monitor_or_main definition_hash['Monitor']
      @workspace = WindowManager.new.find_workspace_or_current definition_hash['Workspace']&.to_i
      normalize_variables
    end

    def to_s
      HEADERS.map { |key| "#{key}: #{raw_definition[key]}" }.join(', ')
    end

    attr_reader :raw_definition, :monitor, :x, :y, :height, :width,
                :workspace, :command, :title, :group

    def hash
      state.hash
    end

    def ==(other)
      other.class == self.class && state == other.state
    end

    alias eql? ==

    protected

    def state
      raw_definition
    end

    private

    def normalize_variables
      %w[Title Command X Y Width Height Group].each do |key|
        name = key.downcase.gsub(/-/, '_')
        value = AttributeNormalizer.new(key, @raw_definition[key], @monitor).normalize
        instance_variable_set "@#{name}".to_sym, value
      end
    end

    def validate_raw(definition)
      validate_headers(definition)
      raise Error, 'No command or window title specified' unless definition['Command'] || definition['Title']

      validate_geometry(definition)

      raise Error, "Invalid monitor=#{definition['Monitor']}" if definition['Monitor']&.to_i&.negative?
    end

    def validate_geometry(definition)
      geometry_field_nil = %w[Width Height X Y].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil
    end

    HEADERS = %w[Title Command Monitor Workspace X Y Width Height Group].freeze

    def validate_headers(definition)
      headers = definition.keys
      return if Set.new(HEADERS).superset?(Set.new(headers))

      actual_headers = headers.join(', ')
      expected_headers = HEADERS.join(', ')
      raise Error, "Invalid configuration file: invalid headers=#{actual_headers}, valid=#{expected_headers}"
    end
  end
end
