# frozen_string_literal: true

module Sapristi
  class Sapristi
    def initialize(configuration_loader: ConfigurationLoader.new, definition_processor: DefinitionProcessor.new)
      @configuration_loader = configuration_loader
      @definition_processor = definition_processor
    end

    def run(conf_file = user_default_configuration_file)
      ::Sapristi.logger.info "Sapristi: Processing: #{conf_file}"
      check_user_configuration(conf_file)

      definitions = @configuration_loader.load(conf_file)

      process definitions
    end

    def verbose!
      ::Sapristi.logger.level = :info
    end

    def dry!
      @dry = true
      ::Sapristi.logger.level = :info if ::Sapristi.logger.level > Logger::INFO
    end

    private

    def process(definitions)
      definitions.each_with_index do |definition, index|
        ::Sapristi.logger.info "Process line #{index}: #{definition.inspect}"
        @definition_processor.process_definition(definition) unless @dry
      rescue Error => e
        raise Error, "#{e.message}, line=#{index}"
      end
    end

    def check_user_configuration(conf_file)
      if conf_file.eql?(user_default_configuration_file) && !File.exist?(conf_file)
        @configuration_loader.create_empty_configuration conf_file
      end
    end

    def user_default_configuration_file
      File.join Dir.home, '.sapristi.csv'
    end
  end
end
