require "csv"

module Sapristi
	class ConfigurationLoader
		SEPARATOR = ","
		def initialize
			@monitor_manager = MonitorManager.new
		end

		def load file
			table = CSV.read(file, headers: true, col_sep: SEPARATOR)
			raise Error, "Invalid configuration file: headers=#{table.headers.join(', ')}, valid=#{valid_headers.join(', ')}" if !table.headers.eql? valid_headers

			table.each_with_index do |definition, index|
				definition["Line"] = index
			end

			table.map{|definition| normalize(definition) }
		rescue Errno::ENOENT
			raise Error, "Configuration file not found: #{file}"
		end

		private
		def valid_headers
			%w(Title Command Monitor X-position Y-position H-size V-size Workspace)
		end

		def normalize definition
			monitor = @monitor_manager.get_monitor definition["monitor"]

			translations = { "H-size" => "x", "V-size" => "y", "X-position" => "x", "Y-position" => "y" }
			normalized = definition.to_h.keys.each_with_object({}) do |k, memo|
				m = definition[k]&.to_s&.match(/^([0-9]{1,2})%$/)
				if m
					if translations[k]
						memo[k] = (monitor[translations[k]] * (m[1].to_i / 100.0)).to_i
					else
						raise "#{k}=#{definition[k]}, using percentage in invalid field, valid=#{translations.keys.join(', ')}"
					end
				else
					memo[k] = definition[k]
				end
			end

			(translations.keys + %w(Workspace)).each {|k| normalized[k] = normalized[k].to_i }
			normalized
		end
	end
end