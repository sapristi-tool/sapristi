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

  class AttributeNormalizer
    def initialize(key, raw, monitor)
      @key = key
      @raw = raw
      @monitor_absolute = monitor[Definition::TRANSLATIONS[key]]
      work_area = monitor['work_area']
      @work_area_x_offset = work_area[0]
      @work_area_y_offset = work_area[1]
    end

    def normalize
      is_percentage = raw&.to_s&.match(/^([0-9]+)%$/)

      if is_percentage
        apply_percentage
      elsif raw.to_s.include?('%')
        raise Error, "key=#{key}, invalid percentage=#{raw}"
      else
        raw
      end
    end

    private

    attr_reader :key, :raw, :monitor_absolute, :work_area_x_offset, :work_area_y_offset

    def apply_percentage
      validate_percentage_field

      value = (monitor_absolute * percentage).to_i
      value += work_area_x_offset if key.eql? 'X-position'
      value += work_area_y_offset if key.eql? 'Y-position'

      value
    end

    def percentage
      value = raw.to_s.match(/^([0-9]+)%$/)[1].to_i
      value / 100.0
    end

    def validate_percentage_field
      translated_key = Definition::TRANSLATIONS[key]
      min_percentage = { 'V-size' => 0.05, 'H-size' => 0.05 }.fetch(key, 0)
      unless translated_key
        raise "#{key}=#{raw}, using percentage in invalid field, valid=#{Definition::TRANSLATIONS.keys.join(', ')}"
      end

      raise Error, "#{key} percentage is invalid=#{raw}, valid=5%-100%" if percentage < min_percentage || percentage > 1
    end
  end
end
