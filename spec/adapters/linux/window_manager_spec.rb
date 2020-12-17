# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  module Linux
    RSpec.describe WindowManager do
      context 'deal with extended window manager hints' do
        let(:display) { double('display') }
        subject { WindowManager.new(display) }

        let(:window_with_maximized_hortz) do
          instance_double('window', id: 1, maximized_horizontally?: true, maximized_vertically?: false)
        end

        let(:window_with_maximized_vert) do
          instance_double('window', id: 1, maximized_horizontally?: false, maximized_vertically?: true)
        end

        let(:geometry) { [100, 100, 100, 100] }

        before(:each) { allow(display).to receive(:action_window) }

        it 'removes wm extended window manager_hints when max_horz' do
          expect(subject).to receive(:remove_extended_hints).with(window_with_maximized_hortz)

          subject.move_resize window_with_maximized_hortz, geometry
        end

        it 'removes wm extended window manager_hints when max_vert' do
          expect(subject).to receive(:remove_extended_hints).with(window_with_maximized_vert)

          subject.move_resize window_with_maximized_vert, geometry
        end
      end

      it('fetch open windows returns same result as command line wmctrl') do
        expected = `wmctrl -l`.split("\n").map { |line| line.split[0].to_i(16) }
        actual = subject.windows.map(&:id)

        expect(actual).to contain_exactly(*expected)
      end

      context('window manipulation') do
        subject { WindowManager.new }

        let(:command) { 'gedit -s --new-window' }
        let(:window) { @windows.push(NewProcessWindowDetector.new.detect_window_for_process(command)).first }
        let(:expected_width) { window.geometry[2] - inc_x }
        let(:expected_height) { window.geometry[3] - inc_y }
        let(:window_geometry) { subject.windows.find { |actual_window| actual_window.id.eql? window.id }.geometry }

        before(:each) { @windows = [] }
        after(:each) { @windows.each { |window| subject.close(window) } }

        it('can resize windows') do
          subject.resize(window, expected_width, expected_height)

          expect(window_geometry[2..3]).to eq([expected_width, expected_height])
        end

        let(:inc_x) { 10 }
        let(:inc_y) { 20 }
        let(:x_pos) { window.geometry[0] + inc_x }
        let(:y_pos) { window.geometry[1] + inc_y }

        it('can move windows') do
          subject.move(window, x_pos, y_pos)

          expect(window_geometry[0..1]).to eq([x_pos, y_pos])
        end

        it('when moving reads size from the system not the window') do
          subject.resize(window, expected_width, expected_height)

          subject.move(window, x_pos, y_pos)

          expect(window_geometry).to eq([x_pos, y_pos, expected_width, expected_height])
        end

        it('when resizing reads position from the system not the window') do
          subject.move(window, x_pos, y_pos)

          subject.resize(window, expected_width, expected_height)

          expect(window_geometry).to eq([x_pos, y_pos, expected_width, expected_height])
        end
      end
    end
  end
end
