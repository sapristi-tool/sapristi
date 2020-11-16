require "spec_helper"

include Sapristi


RSpec.describe WindowManager do
	let(:under_test) { WindowManager.new }

	it('fetch open windows returns same result as command line wmctrl') do
		expected = `wmctrl -l`.split("\n").map {|w| w.split[0].to_i(16) }
		actual = under_test.windows.map(&:id)
		
		expect(actual).to contain_exactly(*expected)
	end

	it ('can resize and move window') do
		pid = Process.spawn("gedit --new-window")
		Process.detach pid

		under_test.windows.find {}
	ensure
		Process.kill "KILL", pid
	end

	context('execute and return window') do
		it('raises and error when command is invalid') do
			expect { under_test.launch("invalid_command") }.to raise_error(Error, /Error executing process: No such file or directory/)
		end

		it('raises and error when command ends') do
			expect { under_test.launch("/bin/ls > /dev/null") }.to raise_error(Error, /Error executing process, is dead/)
		end

		it('raises and error when command does not create a window') do
			expect { under_test.launch("bash -c \"read\"", 1) }.to raise_error(Error, /Error executing process, it didn't open a window/)
		end

		it ('launches a new gedit window and process') do
			user_id = `id -u`.strip
			previous_pids = `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)

			window = under_test.launch("gedit --new-window /tmp/some_file.txt")
			expect(previous_pids).not_to  include(window.pid)
		ensure
			Process.kill "KILL", window.pid if window&.pid
		end


	end
end