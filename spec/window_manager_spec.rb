# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe WindowManager do
    subject { WindowManager.new }

    it('fetch open windows returns same result as command line wmctrl') do
      expected = `wmctrl -l`.split("\n").map { |w| w.split[0].to_i(16) }
      actual = subject.windows.map(&:id)

      expect(actual).to contain_exactly(*expected)
    end

    # FIXME
    it('can resize windows') do
      window = subject.launch('sol')

      inc_x = -10
      inc_y = -20
      expected_width = window.geometry[2] + inc_x
      expected_height = window.geometry[3] + inc_y
      subject.resize(window, expected_width, expected_height)
      sleep 1

      updated_window = subject.windows.find { |w| w.id.eql? window.id }

      expect(updated_window.geometry[2]).to eq(expected_width)
      expect(updated_window.geometry[3]).to eq(expected_height)
    ensure
      # Process.kill "KILL", window.pid if window
      subject.close(window) if window
    end

    # FIXME
    it('can move windows') do
      window = subject.launch('gedit --new-window')

      inc_x = 10
      inc_y = 20
      x = window.geometry[0] + inc_x
      y = window.geometry[1] + inc_y

      subject.move(window, x, y)
      sleep 1

      updated_window = subject.windows.find { |w| w.id.eql? window.id }

      expect(updated_window.geometry[0]).to eq(x)
      expect(updated_window.geometry[1]).to eq(y)
    ensure
      subject.close(window) if window
    end

    context('#find_window') do
	    it 'one window by title' do
	      window = subject.launch('gedit --new-window deleteme_title.txt')

	      actual_windows = subject.find_window(/deleteme_title.txt/)
	                                 .map(&:to_h)
	                                 .map { |w| w.reject { |k| k.eql? :active } }
	      expect(actual_windows).to eq([window.to_h.reject { |k| k.eql? :active }])
	    ensure
	      subject.close(window) if window
	    end

	    it 'two windows by title' do
	      window1 = subject.launch('gedit --new-window deleteme_title.txt')
	      window2 = subject.launch('sol')

	      actual_windows = subject.find_window(/deleteme_title.txt|Klondike/).map(&:to_h)
	      expect(actual_windows.to_a).to have(2).items
	    ensure
	      subject.close(window1) if window1
	      subject.close(window2) if window2
	    end

	    it 'empty list when window not found' do
	      actual_windows = subject.find_window(/no window title/).map(&:to_h)
	      expect(actual_windows.to_a).to have(0).items
	    end
	  end

    context('#launch') do
    	context('raises an error') do
	      it('when command is invalid') do
	        expect { subject.launch('invalid_command') }
	          .to raise_error(Error, /Error executing process: No such file or directory/)
	      end

	      it('when command ends') do
	        expect { subject.launch('/bin/ls > /dev/null') }
	          .to raise_error(Error, /Error executing process, is dead/)
	      end

	      it('when command does not create a window') do
	      	non_dying_command = 'bash -c "read"'
	        expect { subject.launch(non_dying_command, 1) }
	          .to raise_error(Error, /Error executing process, it didn't open a window/)
	      end
    	end

      it('launches a new gedit window and process') do
        user_id = `id -u`.strip
        previous_pids = `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)

        window = subject.launch('gedit --new-window /tmp/some_file.txt')
        expect(previous_pids).not_to include(window.pid)
      ensure
        subject.close(window) if window.pid
      end
    end
  end
end
