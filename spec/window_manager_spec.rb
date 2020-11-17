require "spec_helper"

include Sapristi


RSpec.describe WindowManager do
	let(:under_test) { WindowManager.new }

	it('fetch open windows returns same result as command line wmctrl') do
		expected = `wmctrl -l`.split("\n").map {|w| w.split[0].to_i(16) }
		actual = under_test.windows.map(&:id)
		
		expect(actual).to contain_exactly(*expected)
	end


	#FIXME
	it ('can resize windows') do		
		window = under_test.launch("sol")

		inc_x = -10
		inc_y = -20
		expected_width = window.geometry[2] + inc_x
		expected_height = window.geometry[3] + inc_y
		under_test.resize(window, expected_width, expected_height)
		sleep 1

		updated_window = under_test.windows.find {|w| w.id.eql? window.id }

		
		expect(updated_window.geometry[2]).to eq(expected_width)
		expect(updated_window.geometry[3]).to eq(expected_height)
	ensure
		#Process.kill "KILL", window.pid if window
		under_test.close(window) if window
	end

	#FIXME
	it ('can move windows') do
		window = under_test.launch("gedit --new-window")

		inc_x = 10
		inc_y = 20
		x = window.geometry[0] + inc_x
		y = window.geometry[1] + inc_y

		under_test.move(window, x, y)
		sleep 1

		updated_window = under_test.windows.find {|w| w.id.eql? window.id }

		expect(updated_window.geometry[0]).to eq(x)
		expect(updated_window.geometry[1]).to eq(y)
	ensure Exception
		#Process.kill "KILL", window.pid if window
		under_test.close(window) if window
	end

	it 'find one window by title' do
		window = under_test.launch("gedit --new-window deleteme_title.txt")

		actual_windows = under_test.find_window(/deleteme_title.txt/).map(&:to_h).map {|w| w.reject { |k| k.eql? :active } }
		expect(actual_windows).to eq([window.to_h.reject { |k| k.eql? :active }])
	ensure
		#Process.kill "KILL", window.pid if window
		under_test.close(window) if window
	end

	it 'find two windows by title' do
		window1 = under_test.launch("gedit --new-window deleteme_title.txt")
		window2 = under_test.launch("sol")

		actual_windows = under_test.find_window(/deleteme_title.txt|Klondike/).map &:to_h
		expect(actual_windows.to_a).to have(2).items
		#expect(actual_windows.map(&:title)).to
	ensure
		#Process.kill "KILL", window1.pid if window1
		#Process.kill "KILL", window2.pid if window2
		under_test.close(window1) if window1
		under_test.close(window2) if window2
	end

	it 'returns empty list when window not found' do
		actual_windows = under_test.find_window(/no window title/).map &:to_h
		expect(actual_windows.to_a).to have(0).items
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
			#Process.kill "KILL", window.pid if window&.pid
			under_test.close(window) if window.pid
		end


	end
end