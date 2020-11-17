# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

module Sapristi
  RSpec.describe Sapristi do
    it 'has a version number' do
      expect(VERSION).not_to be nil
    end

    it('defaults to configuration file $HOME/.sapristi.csv') do
      configuration_loader = spy(ConfigurationLoader.new)

      under_test = Sapristi.new(configuration_loader: configuration_loader)

      under_test.run

      expect(configuration_loader).to have_received(:load).with(File.join(Dir.home, '.sapristi.csv'))
    end

    it('creates empty configuration file if it does not exist') do
      configuration_loader = ConfigurationLoader.new
      under_test = Sapristi.new(configuration_loader: configuration_loader)

      mock_conf_file = '/tmp/mocked_file.csv'
      File.delete mock_conf_file if File.exist? mock_conf_file
      allow_any_instance_of(under_test.class).to receive(:user_default_configuration_file).and_return(mock_conf_file)

      under_test.run

      expect(File.exist?(mock_conf_file)).to be_truthy
    end

    it 'process lines in configuration file' do
      definition = { 'Title' => nil, 'Command' => 'sol', 'Monitor' => nil,
                     'X-position' => 0, 'Y-position' => 0, 'H-size' => 500, 'V-size' => 500, 'Workspace' => nil }

      file = Tempfile.create 'foo'
      file_path = file.path
      file.close
      File.delete file_path
      ConfigurationLoader.new.save(file_path, [definition])

      definition_processor = spy(DefinitionProcessor.new)

      Sapristi.new(definition_processor: definition_processor).run file_path

      expect(definition_processor).to have_received(:process_definition).with(definition.transform_keys(&:to_s))
    end

    it 'appends line number to error when processing file' do
      definition = { 'Title' => nil, 'Command' => '', 'Monitor' => nil, 'X-position' => 0,
                     'Y-position' => 0, 'H-size' => 500, 'V-size' => 500, 'Workspace' => nil }

      file = Tempfile.create 'foo'
      file_path = file.path
      file.close
      File.delete file_path
      ConfigurationLoader.new.save(file_path, [definition])

      expect { Sapristi.new.run file_path }.to raise_error Error
    end
  end
end
