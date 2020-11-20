# frozen_string_literal: true

require 'csv'

module Sapristi
  class ConfigurationLoader
    SEPARATOR = ','
    def initialize
      @monitor_manager = MonitorManager.new
    end

    def load(file)
      table = CSV.read(file, headers: true, col_sep: SEPARATOR)
      raise Error, 'Empty file' if table.eql? []

      validate_headers(table)

      table.map { |definition| normalize(definition) }
    rescue Errno::ENOENT
      raise Error, "Configuration file not found: #{file}"
    rescue Error => e
      raise Error, "Invalid configuration file: #{e.message}"
    rescue StandardError => e
      raise Error, "Unable to process configuration file: #{file}, error=#{e.message}"
    end

    def valid_headers
      %w[Title Command Monitor X-position Y-position H-size V-size Workspace]
    end

    def create_empty_configuration(conf_file)
      raise Error, "Trying to write empty configuration on existing file #{conf_file}" if File.exist? conf_file

      File.write(conf_file, valid_headers.join(SEPARATOR))
    end

    def save(conf_file, definitions)
      raise Error, "Trying to write configuration on existing file #{conf_file}" if File.exist? conf_file

      CSV.open(conf_file, 'wb', write_headers: true, headers: valid_headers, col_sep: SEPARATOR) do |csv|
        definitions.each do |definition|
          csv << valid_headers.map do |k|
            raw_key = k + NORMALIZED_FIELD_SUFFIX
            definition.key?(raw_key) ? definition[raw_key] : definition[k]
          end
        end
      end
    end

    private

    def validate_headers(table)
      return if table.headers.eql? valid_headers

      actual_headers = table.headers.join(', ')
      expected_headers = valid_headers.join(', ')
      raise Error, "invalid headers=#{actual_headers}, valid=#{expected_headers}"
    end

    NORMALIZED_FIELD_SUFFIX = '_raw'
    TRANSLATIONS = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace Monitor]).freeze
    def normalize(definition)
      monitor = @monitor_manager.get_monitor definition['monitor']

      normalized = definition.to_h.keys.each_with_object({}) do |key, memo|
        normalize_key(key, definition[key], memo, monitor)
      end

      NUMERIC_FIELDS.each { |k| normalized[k] = normalized[k].to_i if normalized[k] }
      normalized
    end

    def normalize_key(key, raw, memo, monitor)
      is_percentage = raw&.to_s&.match(/^([0-9]{1,2})%$/)

      if is_percentage
        memo[key] = apply_percentage(key, raw, monitor)
        memo[key + NORMALIZED_FIELD_SUFFIX] = raw
      else
        memo[key] = raw
      end
    end

    def apply_percentage(key, raw, monitor)
      applicable = TRANSLATIONS[key]
      raise "#{key}=#{raw}, using percentage in invalid field, valid=#{TRANSLATIONS.keys.join(', ')}" unless applicable

      percentage = raw.to_s.match(/^([0-9]{1,2})%$/)[1].to_i / 100.0
      monitor_absolute = monitor[TRANSLATIONS[key]]

      (monitor_absolute * percentage).to_i
    end
  end
end
