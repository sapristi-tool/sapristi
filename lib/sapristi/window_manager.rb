require 'wmctrl'

module Sapristi
	class WindowManager
		def initialize
			@display = WMCtrl.display
		end

		def windows
			@display.windows
		end
	end
end