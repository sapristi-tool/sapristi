# frozen_string_literal: true

require 'csv'

module Sapristi
  class ConfigurationLoader
    SEPARATOR = ','
    def initialize
      @definition_parser = DefinitionParser.new
    end

    def load(file)
      csv_rows = load_csv(file)

      csv_rows.each_with_index.map do |definition, line|
        @definition_parser.parse(definition)
      rescue Error => e
        raise Error, "Invalid configuration file: #{e.message}, line=#{line}"
      rescue StandardError => e
        raise Error, "Unable to process configuration file: #{file}, line=#{line}, error=#{e.message}"
      end
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
            raw_key = k + DefinitionParser::NORMALIZED_FIELD_SUFFIX
            definition.key?(raw_key) ? definition[raw_key] : definition[k]
          end
        end
      end
    end

    private

    def load_csv(csv_file)
      table = CSV.read(csv_file, headers: true, col_sep: SEPARATOR)
    rescue Errno::ENOENT
      raise Error, "Configuration file not found: #{csv_file}"
    else
      raise Error, 'Invalid configuration file: Empty file' if table.eql? []

      validate_headers(table)
      table
    end

    def validate_headers(table)
      return if table.headers.eql? valid_headers

      actual_headers = table.headers.join(', ')
      expected_headers = valid_headers.join(', ')
      raise Error, "Invalid configuration file: invalid headers=#{actual_headers}, valid=#{expected_headers}"
    end
  end
end
