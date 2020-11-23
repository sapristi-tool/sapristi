# frozen_string_literal: true

module Sapristi
  class MonitorManager
    def initialize
      @os_manager = LinuxXrandrAdapter.new
    end

    def get_monitor(name)
      available = @os_manager.monitors

      return available[name] if available[name]

      main = available.values.find { |m| m['main'] }
      if name
        aval_names = available.keys.join(', ')
        ::Sapristi.logger.warn "Monitor #{name} not found. Using #{main['name']}, available=#{aval_names}"
      end
      main
    end
  end

  class LinuxXrandrAdapter
    RESOLUTION = '(?<x>[0-9]+)/[0-9]+x(?<y>[0-9]+)/[0-9]+'
    OFFSET = '(?<offset_x>[0-9]+)\\+(?<offset_y>[0-9]+)'
    MONITOR_LINE_REGEX = /^\s*+(?<id>[0-9]+):\s*\+(?<main>\*)?(?<name>[^\s]+)\s+#{RESOLUTION}\+#{OFFSET}.*$/.freeze
    def monitors
      list_monitors.split("\n")[1..nil]
                   .map { |line| extract_monitor_info(line) }
                   .each_with_object({}) { |monitor, memo| memo[monitor['name']] = monitor }
    rescue StandardError => e
      raise Error, "Error fetching monitor information: #{e}"
    end

    private

    def list_monitors
      `xrandr --listmonitors`
    end

    def extract_monitor_info(line)
      matcher = line.match(MONITOR_LINE_REGEX)
      matcher.names.each_with_object({}) do |name, memo|
        value = matcher[name]
        memo[name] = value&.match(/^[0-9]+$/) ? value.to_i : value
      end
    end
  end
end
