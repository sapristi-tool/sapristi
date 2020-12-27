# frozen_string_literal: true

require 'optparse'
require 'ostruct'

module Sapristi
  class ArgumentsParser
    def initialize
      @args = OpenStruct.new
    end

    def parse(options)
      ArgumentsParser.build_parser(@args).parse!(options)
      @args
    end

    def self.build_parser(args)
      OptionParser.new do |opts|
        ArgumentsParser.populate_options(opts, args)
      end
    end

    # This method smells of :reek:TooManyStatements
    # rubocop:disable  Metrics/AbcSize
    # rubocop:disable  Metrics/MethodLength
    def self.populate_options(opts, args)
      opts.banner = 'Usage: sapristi [options]'
      opts.on('-v', '--verbose', 'Verbose mode') { |value| args.verbose = value }
      opts.on('-g', '--group GROUP', 'Use named group definitions') { |value| args.group = value }
      opts.on('-w', '--wait-time NUMBER_OF_SECONDS (1-120)', 'Wait time for detecting a window') do |value|
        args.wait_time = parse_integer(value, 1, 120)
      end
      opts.on('--dry-run', 'Dry run') { |value| args.dry = value }
      opts.on('-f', '--file FILE', 'Read configuration from FILE') { |file| args.file = file }
      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
      opts.on('-m', '--monitors', 'Show monitor\'s info') { args.show_monitors = true }
    end
    # rubocop:enable  Metrics/AbcSize
    # rubocop:enable  Metrics/MethodLength

    def self.parse_integer(value, min = nil, max = nil)
      raise OptionParser::InvalidOption, "'#{value}' is not an integer" unless value.match(/^[0-9]+$/)

      integer = value.to_i
      raise OptionParser::InvalidOption, "requires a wait time > 0, provided=#{value}" unless min.nil? || integer >= min
      unless max.nil? || integer <= max
        raise OptionParser::InvalidOption, "requires a wait time <= 120 seconds, provided=#{value}"
      end

      integer
    end
  end
end
