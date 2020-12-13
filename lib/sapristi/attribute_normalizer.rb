# frozen_string_literal: true

module Sapristi
  class AttributeNormalizer
    def initialize(key, raw, monitor)
      @key = key
      @raw = raw
      if Definition::TRANSLATIONS[key]
        @monitor_absolute = monitor[Definition::TRANSLATIONS[key]]
        work_area = monitor['work_area']
        @work_area_x_offset = work_area[0]
        @work_area_y_offset = work_area[1]
      end
    end

    def normalize
      is_percentage = raw&.to_s&.match(/^([0-9]+)%$/)

      if is_percentage
        apply_percentage
      elsif raw.to_s.include?('%')
        raise Error, "key=#{key}, invalid percentage=#{raw}"
      elsif Definition::NUMERIC_FIELDS.include?(@key)
        raw ? raw.to_i : raw
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
