# frozen_string_literal: true

require 'gtk3'

# https://specifications.freedesktop.org/wm-spec/1.4/ar01s03.html
# https://linux.die.net/man/1/xprop

module Sapristi
  class MonitorManager
    def initialize
      @os_manager = LinuxXrandrAdapter.new
    end

    def get_monitor(name)
      available = monitors

      return available[name] if available[name]

      main = available.values.find { |m| m['main'] }
      if name
        aval_names = available.keys.join(', ')
        ::Sapristi.logger.warn "Monitor #{name} not found. Using #{main['name']}, available=#{aval_names}"
      end
      main
    end

    def monitors
      @os_manager.monitors
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
      monitor_info = matcher.names.each_with_object({}) do |name, memo|
        value = matcher[name]
        memo[name] = value&.match(/^[0-9]+$/) ? value.to_i : value
      end

      work_area = get_monitors_work_area[monitor_info['id']]
      monitor_info['work_area'] = [
        work_area.x - monitor_info['offset_x'],
        work_area.y - monitor_info['offset_y'],
        work_area.x + work_area.width - monitor_info['offset_x'],
        work_area.y + work_area.height - monitor_info['offset_y']
      ]
      monitor_info['work_area_width'] = work_area.width
      monitor_info['work_area_height'] = work_area.height

      monitor_info
    end

    def get_monitors_work_area
      Gdk::Screen.default.n_monitors.times.each_with_object({}) do |monitor_id, memo|
        memo[monitor_id] = Gdk::Screen.default.get_monitor_workarea(monitor_id)
      end
    end
  end
end
