# frozen_string_literal: true

module Sapristi
  class AttributeNormalizer
    def initialize(key, raw, monitor)
      @key = key
      @raw = raw
      @monitor = monitor
    end

    def normalize
      if percentage?
        apply_percentage
      elsif not_a_percentage_but_includes_symbol?
        raise Error, "key=#{key}, invalid percentage=#{raw}"
      elsif numeric_field?
        raw&.to_i
      else
        raw
      end
    end

    private

    attr_reader :key, :raw, :monitor

    def percentage?
      raw&.to_s&.match(/^([0-9]+)%$/)
    end

    def not_a_percentage_but_includes_symbol?
      raw.to_s.include?('%')
    end

    def numeric_field?
      Definition::NUMERIC_FIELDS.include?(key)
    end

    def apply_percentage
      validate_percentage_field

      (monitor_absolute * percentage).to_i + offset
    end

    def offset
      work_area = monitor['work_area']

      case key
      when 'X-position'
        work_area[0]
      when 'Y-position'
        work_area[1]
      else
        0
      end
    end

    def monitor_absolute
      translated_key = Definition::TRANSLATIONS[key]
      monitor[translated_key]
    end

    def percentage
      value = raw.to_s.match(/^([0-9]+)%$/)[1].to_i
      value / 100.0
    end

    def validate_percentage_field
      min_percentage = { 'V-size' => 0.05, 'H-size' => 0.05 }.fetch(key, 0)
      unless Definition::TRANSLATIONS.include? key
        raise "#{key}=#{raw}, using percentage in invalid field, valid=#{Definition::TRANSLATIONS.keys.join(', ')}"
      end

      raise Error, "#{key} percentage is invalid=#{raw}, valid=5%-100%" if percentage < min_percentage || percentage > 1
    end
  end
end
