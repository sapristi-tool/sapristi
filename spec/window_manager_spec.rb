# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe WindowManager do
    subject { WindowManager.new }

    it('fetch open windows returns same result as command line wmctrl') do
      expected = `wmctrl -l`.split("\n").map { |line| line.split[0].to_i(16) }
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

      updated_window = subject.windows.find { |actual_window| actual_window.id.eql? window.id }

      expect(updated_window.geometry[2]).to eq(expected_width)
      expect(updated_window.geometry[3]).to eq(expected_height)
    ensure
      # Process.kill "KILL", window.pid if window
      subject.close(window) if window
    end

    # FIXME
    it('can move windows') do
      window = subject.launch('gedit --new-window -s')

      inc_x = 10
      inc_y = 20
      x_pos = window.geometry[0] + inc_x
      y_pos = window.geometry[1] + inc_y

      subject.move(window, x_pos, y_pos)
      sleep 1

      updated_window = subject.windows.find { |actual_window| actual_window.id.eql? window.id }

      expect(updated_window.geometry[0]).to eq(x_pos)
      expect(updated_window.geometry[1]).to eq(y_pos)
    ensure
      subject.close(window) if window
    end

    context('#find_window') do
      it 'one window by title' do
        window = subject.launch('gedit --new-window deleteme_title.txt -s')

        sleep 0.5
        actual_windows = subject.find_window(/deleteme_title.txt/).map(&:to_h)

        expect(actual_windows).to have(1).item
        expect(actual_windows[0][:id]).to eq(window[:id])
      ensure
        subject.close(window) if window
      end

      it 'two windows by title' do
        a_window = subject.launch('gedit --new-window deleteme_title.txt -s')
        another_window = subject.launch('sol')

        actual_windows = subject.find_window(/deleteme_title.txt|Klondike/).map(&:to_h)
        expect(actual_windows.to_a).to have(2).items
      ensure
        subject.close(a_window) if a_window
        subject.close(another_window) if another_window
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

        window = subject.launch('gedit --new-window /tmp/some_file.txt -s')
        expect(previous_pids).not_to include(window.pid)
      ensure
        subject.close(window) if window.pid
      end
    end
  end
end
