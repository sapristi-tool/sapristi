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
      return monitors[name] if monitor_present?(name)

      use_main_monitor name
    end

    def monitors
      @os_manager.monitors
    end

    private

    def monitor_present?(name)
      monitors.key? name
    end

    def use_main_monitor(name)
      main = monitors.values.find { |monitor| monitor['main'] }
      if name
        aval_names = monitors.keys.join(', ')
        ::Sapristi.logger.warn "Monitor #{name} not found. Using #{main['name']}, available=#{aval_names}"
      end
      main
    end
  end

  class LinuxXrandrAdapter
    RESOLUTION = '(?<x>[0-9]+)/[0-9]+x(?<y>[0-9]+)/[0-9]+'
    OFFSET = '(?<offset_x>[0-9]+)\\+(?<offset_y>[0-9]+)'
    MONITOR_LINE_REGEX = /^\s*+(?<id>[0-9]+):\s*\+(?<main>\*)?(?<name>[^\s]+)\s+#{RESOLUTION}\+#{OFFSET}.*$/.freeze

    def initialize
      # https://ruby-gnome2.osdn.jp/hiki.cgi?Gdk%3A%3ADisplay
      @screen = Gdk::Screen.default
    end

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
      monitor_info = LinuxXrandrAdapter.parse_line line

      monitor_info.merge work_area(monitor_info)
    end

    public

    def self.parse_line(line)
      matcher = line.match(MONITOR_LINE_REGEX)
      matcher.names.each_with_object({}) do |name, memo|
        value = matcher[name]
        memo[name] = value&.match(/^[0-9]+$/) ? value.to_i : value
      end
    end

    def work_area(monitor_info)
      area = monitors_work_area[monitor_info['id']]
      {
        'work_area' => LinuxXrandrAdapter.dimensions(area, monitor_info),
        'work_area_width' => area.width,
        'work_area_height' => area.height
      }
    end

    def self.dimensions(work_area, monitor_info)
      offset_x = monitor_info['offset_x']
      offset_y = monitor_info['offset_y']
      x_start = work_area.x
      y_start = work_area.y
      [
        x_start - offset_x,
        y_start - offset_y,
        x_start + work_area.width - offset_x,
        y_start + work_area.height - offset_y
      ]
    end

    def monitors_work_area
      @screen.n_monitors.times.each_with_object({}) do |monitor_id, memo|
        memo[monitor_id] = @screen.get_monitor_workarea(monitor_id)
      end
    end
  end
end
