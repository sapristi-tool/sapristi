require "csv"

module Sapristi
	class ConfigurationLoader
		SEPARATOR = ","
		def load file
			table = CSV.read(file, headers: true, col_sep: SEPARATOR)
		rescue Errno::ENOENT
			raise Error, "Configuration file not found: #{file}"
		end
	end
end