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
end
