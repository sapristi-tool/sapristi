# frozen_string_literal: true

module Sapristi
  class Sapristi
    def initialize(configuration_loader: ConfigurationLoader.new, definition_processor: DefinitionProcessor.new)
      @configuration_loader = configuration_loader
      @definition_processor = definition_processor
    end

    def run(conf_file = user_default_configuration_file)
      ::Sapristi.logger.info "Sapristi: Processing: #{conf_file}"
      if conf_file.eql?(user_default_configuration_file) && !File.exist?(conf_file)
        @configuration_loader.create_empty_configuration conf_file
      end

      definitions = @configuration_loader.load(conf_file)

      definitions.each_with_index do |definition, index|
        ::Sapristi.logger.info "Process line #{index}: #{definition.inspect}"
        @definition_processor.process_definition(definition) unless @dry
      rescue Error => e
        raise Error, "#{e.message}, line=#{index}"
      end
    end

    def verbose!
      ::Sapristi.logger.level = :info
    end

    def dry!
      @dry = true
      ::Sapristi.logger.level = :info if ::Sapristi.logger.level > Logger::INFO
    end

    private

    USER_CONFIGURATION_FILE = File.join Dir.home, '.sapristi.csv'
    def user_default_configuration_file
      USER_CONFIGURATION_FILE
    end
  end
end
