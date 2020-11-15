module Sapristi
	class MonitorManager
		def get_monitor name
			monitors[name]
		end

		private
		def monitors
			list_monitors.split("\n")[1..nil]
				.map {|line| line.match(/^\s*+(?<id>[0-9]+):\s*\+(?<main>\*)?(?<name>[^\s]+)\s+(?<x>[0-9]+)\/[0-9]+x(?<y>[0-9]+)\/[0-9]+\+(?<offset_x>[0-9]+)\+(?<offset_y>[0-9]+).*$/)}
				.map {|m| m.names.each_with_object({}) {|name, memo| memo[name] = m[name]&.match(/^[0-9]+$/) ? m[name].to_i : m[name] }}
				.each_with_object({}) {|monitor, memo| memo[monitor["name"]] = monitor }
		rescue StandardError => e
			raise Error.new "Error fetching monitor information: #{e}"
		end

		def list_monitors
			`xrandr --listmonitors`
		end
	end
end