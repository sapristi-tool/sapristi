# frozen_string_literal: true

module Sapristi
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

      Monitor.new monitor_info.merge work_area(monitor_info)
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
