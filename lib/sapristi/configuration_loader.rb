require "csv"

module Sapristi
	class ConfigurationLoader
		SEPARATOR = ","
		def load file
			table = CSV.read(file, headers: true, col_sep: SEPARATOR)
			raise Error, "Invalid configuration file: headers=#{table.headers.join(', ')}, valid=#{valid_headers.join(', ')}"
		rescue Errno::ENOENT
			raise Error, "Configuration file not found: #{file}"
		end

		private
		def valid_headers
			%w(Title Command Monitor X-position Y-position H-size V-size Workspace)
		end
	end
end