# frozen_string_literal: true

require 'sapristi/version'
require 'sapristi/attribute_normalizer'
require 'sapristi/monitor_manager'
require 'sapristi/definition_parser'
require 'sapristi/configuration_loader'
require 'sapristi/definition'
require 'sapristi/window_manager'
require 'sapristi/definition_processor'
require 'sapristi/sapristi'
require 'sapristi/arguments_parser'
require 'sapristi/adapters/linux/monitor_manager'
require 'sapristi/adapters/linux/window_manager'
require 'sapristi/adapters/linux/process_manager'
require 'sapristi/new_process_window_detector'
require 'sapristi/monitor'
require 'sapristi/adapters/os_factory'
require 'logger'

module Sapristi
  class Error < StandardError; end

  def self.logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.progname = name
      log.level = Logger::WARN

      log.formatter = proc do |_severity, _datetime, _progname, msg|
        "#{msg}\n"
      end
    end
  end
end
