# frozen_string_literal: true

module Sapristi
  class Definition
    TRANSLATIONS = {
      'H-size' => 'work_area_width', 'V-size' => 'work_area_height',
      'X-position' => 'work_area_width', 'Y-position' => 'work_area_height'
    }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace]).freeze

    def initialize(definition_hash)
      @raw = definition_hash
      validate(definition_hash)
      @to_h = {}
      @raw = definition_hash.to_h
      raise Error, 'Invalid monitor=-1' if definition_hash['Monitor']&.to_i&.negative?

      the_monitor = MonitorManager.new.get_monitor definition_hash['Monitor']&.to_i
      self['Monitor'] = the_monitor

      %w[Title Command X-position Y-position H-size V-size Workspace].each do |variable|
        raw = definition_hash[variable]
        # value = normalize variable, raw
        normalized_value = AttributeNormalizer.new(variable, raw, the_monitor).normalize
        instance_variable_set "@#{Definition.normalize_key variable}".to_sym, normalized_value
        @to_h[variable] = normalized_value
      end

      NUMERIC_FIELDS.each { |field| self[field] = self[field].to_i if self[field] }

      self['Workspace'] ||= WindowManager.new.workspaces.find(&:current).id
    end

    def raw(field)
      @raw[field]
    end

    def raw_key?(field)
      @raw.key?(field)
    end

    attr_reader :monitor, :x_position, :y_position, :v_size, :h_size, :workspace, :command, :title

    # scaffolding
    def [](key)
      @to_h[key]
    end

    def []=(key, value)
      @to_h[key] = value
      instance_variable_set "@#{Definition.normalize_key key}".to_sym, value
    end

    def to_h
      @raw
    end
    # scaffolding

    def self.normalize_key(key)
      key.downcase.gsub(/-/, '_')
    end

    private

    def validate(definition)
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil
    end
  end
end
