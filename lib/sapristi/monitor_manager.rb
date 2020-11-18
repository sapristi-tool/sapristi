# frozen_string_literal: true

module Sapristi
  class MonitorManager
    def get_monitor(name)
      available_monitors = monitors

      return available_monitors[name] if available_monitors[name]

      main = available_monitors.values.find { |m| m['main'] }
      puts "Monitor #{name} not found. Using #{main['name']}, available=#{available_monitors.keys.join(', ')}" if name
      main
    end

    private

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

    def list_monitors
      `xrandr --listmonitors`
    end

    def extract_monitor_info(line)
      m = line.match(MONITOR_LINE_REGEX)
      m.names.each_with_object({}) { |name, memo| memo[name] = m[name]&.match(/^[0-9]+$/) ? m[name].to_i : m[name] }
    end
  end
end
