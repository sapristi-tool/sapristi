require 'wmctrl'

module Sapristi
	class WindowManager
		def initialize
			@display = WMCtrl.display
		end

		def windows
			@display.windows
		end

		def launch cmd, timeout_in_seconds = 30
			windows = @display.windows
			windows_data = windows.map {|w| w.to_h }

			user_id = `id -u`.strip
			previous_pids = `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)

			process_pid = Process.spawn(cmd) rescue (raise Error, "Error executing process: #{$!.to_s}")
			puts "Launch #{cmd.split[0]}, process=#{process_pid}"
			waiter = Process.detach process_pid

			
			start_time = Time.now
			while Time.now - start_time < timeout_in_seconds && waiter.alive?
				new_windows_found = @display.windows.filter {|w| !windows_data.include? w.to_h }.filter {|w| !previous_pids.include? w.pid}

				new_windows_found.each {|a| puts "  Found new window=#{a.pid}, process=#{process_pid}: #{a.title}"}
				process_window = new_windows_found.find {|window| window.pid.eql? process_pid }
				
				break if process_window
				
				sleep 0.5
			end

			if !waiter.alive?
				raise Error, "Error executing process, is dead"
			end

			if process_window.nil?
				Process.kill"KILL", process_pid
				raise Error, "Error executing process, it didn't open a window"
			end

			puts "Found window title=#{process_window.title} for process=#{process_pid}!"
			process_window
		end
	end
end