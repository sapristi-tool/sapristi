# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'ostruct'

# rubocop:disable Style/MixinUsage:
include Sapristi
# rubocop:enable Style/MixinUsage:

RSpec.describe ConfigurationLoader do
  subject { ConfigurationLoader.new }

  let(:non_existing_file) do
    build(:non_existent_file_path)
  end

  let(:file_path) do
    file = '/tmp/some.csv'
    File.delete file if File.exist? file
    file
  end

  let(:valid_headers) { %w[Title Command Monitor X-position Y-position H-size V-size Workspace] }
  let(:valid_csv) do
    build(:valid_csv_file_path, rows: build(:valid_definition_hashes))
  end

  let(:valid_csv_definitions) do
    build(:valid_csv_definitions)
  end

  context('#load') do
    context('raises an error') do
      it 'when configuration file is not found' do
        expect do
          subject.load(non_existing_file)
        end.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
      end

      it 'when csv is empty' do
        empty_file = Tempfile.create('foo')
        empty_file.close

        expect { subject.load(empty_file) }.to raise_error(Error, /Invalid configuration file: Empty file/)
      end
    end
  end

  context('#save') do
    context('raises and error') do
      it 'when creating an empty configuration on an existing file' do
        file = Tempfile.new('foo')
        file.close

        expect do
          subject.create_empty_configuration file.path
        end.to raise_error Error, /Trying to write empty configuration on existing file #{file.path}/
      ensure
        file.unlink
      end

      it 'when saving configuration on an existing file' do
        file = Tempfile.new('foo')
        file.close

        expect do
          subject.save file.path, nil
        end.to raise_error Error, /Trying to write configuration on existing file #{file.path}/
      ensure
        file.unlink
      end
    end

    it 'saves definitions' do
      subject.save file_path, valid_csv_definitions

      expect(subject.load(file_path))
        .to eq(valid_csv_definitions)
    end

    it 'writes empty configuration' do
      subject.create_empty_configuration non_existing_file
      expect(File.read(non_existing_file)).to eql Definition::HEADERS.join(ConfigurationLoader::SEPARATOR)
    end
  end
end
