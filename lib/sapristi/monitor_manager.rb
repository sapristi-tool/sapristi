module Sapristi
	class MonitorManager
		def get_monitor name
			`axrandr --listmonitors`
		rescue StandardError => e
			raise Error.new "Error fetching monitor information: #{e}"
		end
	end
end