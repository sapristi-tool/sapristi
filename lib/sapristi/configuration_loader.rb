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
      unless table.headers.eql? valid_headers
        actual_headers = table.headers.join(', ')
        expected_headers = valid_headers.join(', ')
        raise Error, "Invalid configuration file: headers=#{actual_headers}, valid=#{expected_headers}"
      end

      table.map { |definition| normalize(definition) }
    rescue Errno::ENOENT
      raise Error, "Configuration file not found: #{file}"
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

    NORMALIZED_FIELD_SUFFIX = '_raw'
    TRANSLATIONS = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace Monitor]).freeze
    def normalize(definition)
      monitor = @monitor_manager.get_monitor definition['monitor']

      normalized = definition.to_h.keys.each_with_object({}) do |k, memo|
        is_percentage = definition[k]&.to_s&.match(/^([0-9]{1,2})%$/)

        if is_percentage
          value = apply_percentage k, definition[k], monitor
          memo[k] = value[:value]
          memo[k + NORMALIZED_FIELD_SUFFIX] = value[:raw]
        else
          memo[k] = definition[k]
        end
      end

      NUMERIC_FIELDS.each { |k| normalized[k] = normalized[k].to_i if normalized[k] }
      normalized
    end

    def apply_percentage(key, raw, monitor)
      applicable = TRANSLATIONS[key]
      raise "#{key}=#{raw}, using percentage in invalid field, valid=#{TRANSLATIONS.keys.join(', ')}" unless applicable

      m = raw&.to_s&.match(/^([0-9]{1,2})%$/)
      value = (monitor[TRANSLATIONS[key]] * (m[1].to_i / 100.0)).to_i

      { value: value, raw: raw }
    end
  end
end
