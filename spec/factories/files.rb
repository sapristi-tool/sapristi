# frozen_string_literal: true

module Helper
  def self.produce_csv_file(rows)
    header_line = HEADERS.join(SEPARATOR)
    body_lines = rows.map { |row| line(row) }
    write_lines [header_line].concat body_lines
  end

  def self.line(row)
    HEADERS.map { |field| row[field] }.join(SEPARATOR)
  end

  def self.write_lines(lines)
    file = '/tmp/source.csv'
    File.write file, lines.join("\n")

    file
  end
end

HEADERS = %w[Title Command Monitor X-position Y-position H-size V-size Workspace].freeze
SEPARATOR = ','

FactoryBot.define do
  factory :non_existent_file_path, class: String do
    file_path { '/tmp/non_existent_file' }

    initialize_with do
      File.delete file_path if File.exist? file_path
      file_path
    end
  end

  factory :invalid_csv_file_path, class: String do
    initialize_with do
      file = Tempfile.new('foo')
      file.write('hello world')
      file.close
      file.path
    end
  end

  factory :headers, class: Array do
    initialize_with { HEADERS }
  end

  factory :valid_csv_file_path, class: String do
    rows { [] }

    initialize_with do
      Helper.produce_csv_file rows.map(&:to_h)
    end
  end
end
