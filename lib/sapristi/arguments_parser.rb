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

    def self.populate_options(opts, args)
      opts.banner = 'Usage: sapristi [options]'
      opts.on('-v', '--verbose', 'Verbose mode') { |value| args.verbose = value }
      opts.on('--dry-run', 'Dry run') { |value| args.dry = value }
      opts.on('-f', '--file FILE', 'Read configuration from FILE') { |file| args.file = file }
      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end
  end
end
