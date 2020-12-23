# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe WindowManager do
    subject { WindowManager.new }

    before(:each) { @windows = [] }
    after(:each) { @windows.each { |window| subject.close(window) } }

    def launch_n_windows(number_of_windows, command = 'sol')
      number_of_windows.times { |_i| @windows.push NewProcessWindowDetector.new.detect_window_for_process(command, nil) }
      sleep 0.25
      @windows
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
  end
end
