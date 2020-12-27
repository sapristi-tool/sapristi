# frozen_string_literal: true

module Sapristi
  class Sapristi
    def initialize(configuration_loader: ConfigurationLoader.new, definition_processor: DefinitionProcessor.new)
      @configuration_loader = configuration_loader
      @definition_processor = definition_processor
      @dry = false
      @verbose = false
      @group = nil
    end

    def run(conf_file = Sapristi.user_default_configuration_file)
      ::Sapristi.logger.info "Sapristi: Processing: #{conf_file}"
      check_user_configuration(conf_file)

      definitions = @configuration_loader.load(conf_file)
      definitions = definitions.filter { |definition| definition.group.eql? @group } if @group

      process definitions
    end

    attr_reader :dry, :verbose

    def verbose!
      @verbose = true
      ::Sapristi.logger.level = :info
    end

    def dry!
      @dry = true
      logger = ::Sapristi.logger
      logger.level = :info if logger.level > Logger::INFO
    end

    def filter!(group)
      @group = group
    end

    private

    def process(definitions)
      definitions.each_with_index do |definition, index|
        process_line(definition, index)
      rescue Error => e
        raise Error, "#{e.message}, line=#{index}"
      end
    end

    def process_line(definition, index)
      ::Sapristi.logger.info "Process line #{index}: #{definition}"
      @definition_processor.process_definition(definition) unless dry
    end

    def check_user_configuration(conf_file)
      return unless conf_file.eql?(Sapristi.user_default_configuration_file) && !File.exist?(conf_file)

      @configuration_loader.create_empty_configuration conf_file
    end

    def self.user_default_configuration_file
      File.join Dir.home, '.sapristi.csv'
    end
  end
end
