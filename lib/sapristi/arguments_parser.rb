# frozen_string_literal: true

require 'optparse'
require 'ostruct'

module Sapristi
  class ArgumentsParser
    def parse(options)
      args = OpenStruct.new

      build_parser(args).parse!(options)
      args
    end

    private

    def build_parser(args)
      OptionParser.new do |opts|
        opts.banner = 'Usage: sapristi [options]'

        opts.on('-v', '--verbose', 'Verbose mode') { |n| args.verbose = n }

        opts.on('--dry-run', 'Dry run') { |n| args.dry = n }

        opts.on('-f', '--file FILE', 'Read configuration from FILE') { |file| args.file = file }

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
    end
  end
end
