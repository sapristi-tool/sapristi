# frozen_string_literal: true

require 'sapristi/version'
require 'sapristi/monitor_manager'
require 'sapristi/configuration_loader'
require 'sapristi/window_manager'
require 'sapristi/definition_processor'
require 'sapristi/sapristi'
require 'sapristi/arguments_parser'
require 'logger'

module Sapristi
  class Error < StandardError; end

  def self.logger
    @logger ||= Logger.new($stdout).tap do |log|
      log.progname = name
      log.level = Logger::INFO
    end
  end
end
