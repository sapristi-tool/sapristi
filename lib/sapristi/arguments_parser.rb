# frozen_string_literal: true

require 'optparse'
require 'ostruct'

module Sapristi
  class ArgumentsParser
    def parse(options)
      args = OpenStruct.new

      opt_parser = OptionParser.new do |opts|
        name = 'sapristi'
        opts.banner = "Usage: #{name} [options]"

        opts.on('-v', '--verbose', 'Verbose mode') do |n|
          args.verbose = n
        end

        opts.on('--dry-run', 'Dry run') do |n|
          args.dry = n
        end

        opts.on('-f', '--file FILE', 'Read configuration from FILE') do |file|
          args.file = file
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end

      opt_parser.parse!(options)
      args
    end
  end
end
