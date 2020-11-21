# frozen_string_literal: true

require 'csv'

module Sapristi
  class ConfigurationLoader
    SEPARATOR = ','
    def initialize
      @monitor_manager = MonitorManager.new
      @window_manager = WindowManager.new
    end

    def load(file)
      csv_rows = load_csv(file)

      csv_rows.each_with_index.map do |definition, line|
        normalize(definition)
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
            raw_key = k + NORMALIZED_FIELD_SUFFIX
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

    NORMALIZED_FIELD_SUFFIX = '_raw'
    TRANSLATIONS = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }.freeze
    NUMERIC_FIELDS = (TRANSLATIONS.keys + %w[Workspace Monitor]).freeze
    def normalize(definition)
      raise Error, 'No command or window title specified' if definition['Command'].nil? && definition['Title'].nil?

      geometry_field_nil = %w[H-size V-size X-position Y-position].find { |key| definition[key].nil? }
      raise Error, "No #{geometry_field_nil} specified" if geometry_field_nil

      monitor = @monitor_manager.get_monitor definition['monitor']

      normalized = definition.to_h.keys.each_with_object({}) do |key, memo|
        normalize_key(key, definition[key], memo, monitor)
      end

      NUMERIC_FIELDS.each { |k| normalized[k] = normalized[k].to_i if normalized[k] }
      normalized['Workspace'] ||= @window_manager.workspaces.find(&:current).id

      x = normalized['X-position']
      y = normalized['Y-position']
      window_width = normalized['H-size']
      window_height = normalized['V-size']
      x_end = x + window_width
      y_end = y + window_height
      monitor_width = monitor['x']
      monitor_height = monitor['y']
      min_x_size = 50
      min_y_size = 50
      workspace = normalized['Workspace']
      workspaces_number = @window_manager.workspaces.size

      unless (0...monitor_width).include? x
        raise Error, "x=#{x} is outside of monitor width dimension=0..#{monitor_width - 1}"
      end
      unless (0...monitor_height).include? y
        raise Error, "y=#{y} is outside of monitor height dimension=0..#{monitor_height - 1}"
      end
      if x_end >= monitor_width
        raise Error, "window x dimensions: [#{x}, #{x_end}] exceeds monitor width [0..#{monitor_width - 1}]"
      end
      if y_end >= monitor_height
        raise Error, "window y dimensions: [#{y}, #{y_end}] exceeds monitor height [0..#{monitor_height - 1}]"
      end
      raise Error, "window x size=#{window_width} less than #{min_x_size}" if window_width < min_x_size
      raise Error, "window y size=#{window_height} less than #{min_y_size}" if window_height < min_y_size

      unless (0...workspaces_number).include? workspace
        raise Error, "invalid workspace=#{workspace} valid=0..#{workspaces_number - 1}"
      end

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
