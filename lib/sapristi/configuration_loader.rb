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
        raise Error, "Invalid configuration file: headers=#{table.headers.join(', ')}, valid=#{valid_headers.join(', ')}"
      end

      table.each_with_index do |definition, index|
        # definition["Line"] = index
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
          csv << valid_headers.map { |k| definition.key?(k + NORMALIZED_FIELD_SUFFIX) ? definition[k + NORMALIZED_FIELD_SUFFIX] : definition[k] }
        end
      end
    end

    private

    NORMALIZED_FIELD_SUFFIX = '_raw'
    def normalize(definition)
      monitor = @monitor_manager.get_monitor definition['monitor']

      translations = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }
      normalized = definition.to_h.keys.each_with_object({}) do |k, memo|
        m = definition[k]&.to_s&.match(/^([0-9]{1,2})%$/)
        if m
          if translations[k]
            memo[k] = (monitor[translations[k]] * (m[1].to_i / 100.0)).to_i
            memo[k + NORMALIZED_FIELD_SUFFIX] = definition[k]
          else
            raise "#{k}=#{definition[k]}, using percentage in invalid field, valid=#{translations.keys.join(', ')}"
          end
        else
          memo[k] = definition[k]
        end
      end

      (translations.keys + %w[Workspace Monitor]).each { |k| normalized[k] = normalized[k].to_i if normalized[k] }
      normalized
    end
  end
end
