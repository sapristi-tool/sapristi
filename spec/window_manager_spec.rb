require "spec_helper"

include Sapristi


RSpec.describe WindowManager do
	let(:under_test) { WindowManager.new }

	it('fetch open windows returns same result as command line wmctrl') do
		expected = `wmctrl -l`.split("\n").map {|w| w.split[0].to_i(16) }
		actual = under_test.windows.map(&:id)
		
		expect(actual).to contain_exactly(*expected)
	end

=begin

move and resize work on their own but fails in the test suite

X Error of failed request:  BadWindow (invalid Window parameter)
  Major opcode of failed request:  20 (X_GetProperty)
  Resource id in failed request:  0x2200008
  Serial number of failed request:  1095
  Current serial number in output stream:  1095
=end
	#FIXME
	xit ('can resize windows') do
		window = under_test.launch("sol")

		inc_x = 100
		inc_y = 200
		expected_width = window.geometry[2] + inc_x
		expected_height = window.geometry[3] + inc_y

		under_test.resize(window, expected_width, expected_height)

		updated_window = under_test.windows.find {|w| w.id.eql? window.id }

		
		expect(updated_window.geometry[2]).to eq(expected_width)
		expect(updated_window.geometry[3]).to eq(expected_height)
	ensure
		Process.kill "KILL", window.pid if window
	end

	#FIXME
	xit ('can move windows') do
		window = under_test.launch("gedit --new-window")

		inc_x = 10
		inc_y = 20
		x = window.geometry[0] + inc_x
		y = window.geometry[1] + inc_y

		under_test.move(window, x, y)

		updated_window = under_test.windows.find {|w| w.id.eql? window.id }

		expect(updated_window.geometry[0]).to eq(x)
		expect(updated_window.geometry[1]).to eq(y)
	ensure Exception
		Process.kill "KILL", window.pid if window
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
		ensure Exception
			Process.kill "KILL", window.pid if window&.pid
		end


	end
end