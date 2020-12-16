# frozen_string_literal: true

require 'csv'

module Sapristi
  class ConfigurationLoader
    SEPARATOR = ','
    def initialize
      @definition_parser = DefinitionParser.new
    end

    def load(file_path)
      csv_rows = load_csv(file_path)

      parse_rows(csv_rows, file_path)
    end

    def create_empty_configuration(conf_file)
      raise Error, "Trying to write empty configuration on existing file #{conf_file}" if File.exist? conf_file

      File.write(conf_file, Definition::HEADERS.join(SEPARATOR))
    end

    def save(conf_file, definitions)
      raise Error, "Trying to write configuration on existing file #{conf_file}" if File.exist? conf_file

      serialized = definitions.map { |definition| serialize definition }

      write_to_csv conf_file, serialized
    end

    private

    def write_to_csv(conf_file, serialized)
      CSV.open(conf_file, 'wb', write_headers: true, headers: Definition::HEADERS, col_sep: SEPARATOR) do |csv|
        serialized.each { |definition| csv << definition }
      end
    end

    def serialize(definition)
      Definition::HEADERS.map do |field|
        definition.raw_definition[field]
      end
    end

    def parse_rows(csv_rows, file)
      csv_rows.each_with_index.map do |definition, line|
        @definition_parser.parse(definition)
      rescue Error => e
        raise Error, "Invalid configuration file: #{e.message}, line=#{line}, file=#{file}"
      rescue StandardError => e
        raise Error, "Unable to process configuration file: #{file}, line=#{line}, error=#{e.message}"
      end
    end

    def load_csv(csv_file)
      table = CSV.read(csv_file, headers: true, col_sep: SEPARATOR)
    rescue Errno::ENOENT
      raise Error, "Configuration file not found: #{csv_file}"
    else
      raise Error, "Invalid configuration file: Empty file #{csv_file}" if table.eql? []

      table.map(&:to_h)
    end
  end
end
