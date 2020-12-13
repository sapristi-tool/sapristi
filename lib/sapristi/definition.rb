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
        self[variable] = normalized_value
      end

      #NUMERIC_FIELDS.each { |field| self[field] = self[field].to_i if self[field] }
      NUMERIC_FIELDS.each do |key|
        field = Definition.normalize_key(key)
        value = send(field)
        #send("#{field}=", value.to_i) if value
        #self[field] = value.to_i if value
        #require "pry";binding.pry
        if value
          @to_h[key] = value.to_i
          instance_variable_set "@#{field}".to_sym, value.to_i
        end
      end

      self['Workspace'] = self.workspace || WindowManager.new.workspaces.find(&:current).id
    end

    attr_reader :monitor, :x_position, :y_position, :v_size, :h_size, :workspace, :command, :title

    def raw_definition
      @raw
    end

    # scaffolding
    #def [](key)
    #  @to_h[key]
    #end

    # scaffolding

    private

    def []=(key, value)
      @to_h[key] = value
      instance_variable_set "@#{Definition.normalize_key key}".to_sym, value
    end

    def self.normalize_key(key)
      key.downcase.gsub(/-/, '_')
    end

    def validate(definition)
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil
    end
  end
end
