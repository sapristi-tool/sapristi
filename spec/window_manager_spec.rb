# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe WindowManager do
    subject { WindowManager.new }

    before(:each) { @windows = [] }
    after(:each) { @windows.each { |window| subject.close(window) } }

    def launch_n_windows(number_of_windows, command = 'sol')
      number_of_windows.times { |_i| @windows.push subject.launch(command) }
      sleep 0.5
      @windows
    end

    it('fetch open windows returns same result as command line wmctrl') do
      expected = `wmctrl -l`.split("\n").map { |line| line.split[0].to_i(16) }
      actual = subject.windows.map(&:id)

      expect(actual).to contain_exactly(*expected)
    end

    # FIXME
    context('window manipulation') do
      let(:window) { launch_n_windows(1, 'gedit --new-window -s').first }
      let(:expected_width) { window.geometry[2] - inc_x }
      let(:expected_height) { window.geometry[3] - inc_y }
      let(:window_geometry) { subject.windows.find { |actual_window| actual_window.id.eql? window.id }.geometry }

      it('can resize windows') do
        subject.resize(window, expected_width, expected_height)
        sleep 0.5

        expect(window_geometry[2..3]).to eq([expected_width, expected_height])
      end

      let(:inc_x) { 10 }
      let(:inc_y) { 20 }
      let(:x_pos) { window.geometry[0] + inc_x }
      let(:y_pos) { window.geometry[1] + inc_y }

      it('can move windows') do
        subject.move(window, x_pos, y_pos)
        sleep 0.6

        expect(window_geometry[0..1]).to eq([x_pos, y_pos])
      end

      it('when moving reads size from the system not the window') do
        subject.resize(window, expected_width, expected_height)
        sleep 0.6

        subject.move(window, x_pos, y_pos)
        expect(window_geometry).to eq([x_pos, y_pos, expected_width, expected_height])
      end

      it('when resizing reads position from the system not the window') do
        subject.move(window, x_pos, y_pos)
        sleep 0.6

        subject.resize(window, expected_width, expected_height)
        expect(window_geometry).to eq([x_pos, y_pos, expected_width, expected_height])
      end
    end

    context('#find_window') do
      it 'one window by title' do
        expected = launch_n_windows(1, 'gedit --new-window deleteme_title.txt -s').map(&:id)

        actual_windows = subject.find_window(/deleteme_title.txt/).map(&:id)

        expect(actual_windows).to eq(expected)
      end

      it 'two windows by title' do
        expected = launch_n_windows(2, 'sol').map(&:id)

        actual_windows = subject.find_window(/Klondike/).map(&:id)
        expect(actual_windows.to_a).to eq(expected)
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
        previous_pids = current_user_pids
        window = subject.launch('gedit --new-window /tmp/some_file.txt -s')
        expect(previous_pids).not_to include(window.pid)
      ensure
        subject.close(window) if window
      end

      let(:user_id) { `id -u`.strip }
      let(:current_user_pids) { `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i) }
    end
  end
end
