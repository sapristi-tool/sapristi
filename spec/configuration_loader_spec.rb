# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

module Sapristi
  RSpec.describe ConfigurationLoader do
    subject { ConfigurationLoader.new }

    let(:non_existing_file) do
      '/tmp/non_existent_file_path.csv'
    end

    let(:invalid_csv) do
      file = Tempfile.new('foo')
      file.write('hello world')
      file.close
      file.path
    end

    let(:valid_headers) { %w[Title Command Monitor X-position Y-position H-size V-size Workspace] }
    let(:separator) { ',' }

    let(:valid_csv) do
      file = Tempfile.new('bar')
      file.write(valid_headers.join(separator))
      file.write "\n"
      valid_csv_definitions.each do |valid_definition|
        file.write valid_headers.map { |header| valid_definition[header] }.join(separator)
        file.write "\n"
      end
      file.close

      file.path
    end

    let(:valid_csv_definitions) do
      [
        { 'Title' => nil, 'Command' => 'some', 'Monitor' => nil, 'X-position' => 1,
          'Y-position' => 2, 'H-size' => 3, 'V-size' => 4, 'Workspace' => 5 },
        { 'Title' => 'some title', 'Command' => nil, 'Monitor' => 6, 'X-position' => 7,
          'Y-position' => 8, 'H-size' => 9, 'V-size' => 10, 'Workspace' => 11 },
        { 'Title' => 'some title', 'Command' => nil, 'Monitor' => 0, 'X-position' => '10%',
          'Y-position' => '20%', 'H-size' => '30%', 'V-size' => '40%', 'Workspace' => 11 }
      ]
    end

    context('load') do
      it 'raises an error when configuration file is not found' do
        expect do
          subject.load(non_existing_file)
        end.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
      end

      it 'raises an error when csv format is invalid' do
        expect { subject.load(invalid_csv) }.to raise_error(Error, /Invalid configuration file: headers/)
      end
    end

    context('save') do
      it 'raises an error when creating an empty configuration on an existing file' do
        file = Tempfile.new('foo')
        file.close

        expect do
          subject.create_empty_configuration file.path
        end.to raise_error Error, /Trying to write empty configuration on existing file #{file.path}/
      ensure
        file.unlink
      end

      it 'raises an error when saving configuration on an existing file' do
        file = Tempfile.new('foo')
        file.close

        expect do
          subject.save file.path, nil
        end.to raise_error Error, /Trying to write configuration on existing file #{file.path}/
      ensure
        file.unlink
      end

      it 'saves configuration' do
        file = Tempfile.new('foo')
        file.close
        file_path = file.path
        file.unlink

        subject.save file_path, valid_csv_definitions

        expect(subject.load(file_path)).to eq(valid_csv_definitions.map { |d| subject.send :normalize, d })
      end

      it 'writes empty configuration' do
        file = Tempfile.new('foo')
        file.close
        file_path = file.path
        file.unlink

        subject.create_empty_configuration file_path
        expect(File.read(file_path)).to eql subject.valid_headers.join(ConfigurationLoader::SEPARATOR)
      end
    end

    context 'configuration file' do
      let(:content) { subject.load(valid_csv) }

      let(:xrandr_example) do
        %(Monitors: 2
	 0: +*some 3840/597x2160/336+0+0  DP-1
	 1: +another 1920/509x1080/286+3840+0  HDMI-1)
      end

      it 'numeric fields are integers' do
        %w[X-position Y-position H-size V-size Workspace].each do |field|
          expect(content[1][field]).not_to be_nil
          expect(content[1][field]).to be_instance_of Integer
        end
      end

      it 'apply percentage using monitor dimensions position fields' do
        translations = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }

        %w[X-position Y-position H-size V-size].each do |field|
          monitor = { id: 0, name: 'some',
                      main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s)
          allow_any_instance_of(MonitorManager).to receive(:list_monitors).and_return(xrandr_example)

          expected = ((valid_csv_definitions[2][field][0..-2].to_i / 100.0) * monitor[translations[field]]).to_i
          expect(content[2][field]).to be expected
        end
      end
    end
  end
end
