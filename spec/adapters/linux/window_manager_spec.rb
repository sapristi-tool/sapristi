# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  module Linux
    RSpec.describe WindowManager do
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
        let(:a_geometry) { [200, 200, 600, 600] }

        it 'removes wm extended window manager_hints when max_horz' do
          subject.display.action_window(window.id, :change_state, 'add', 'maximized_horz')
          sleep 0.25
          window_with_maximized_horz = subject.windows(id: window.id).first
          expect(window_with_maximized_horz.maximized_horizontally?).to be_truthy

          subject.move_resize window_with_maximized_horz, a_geometry
          expect(subject.windows(id: window.id).first.maximized_horizontally?).to be_falsey
        end

        it 'removes wm extended window manager_hints when max_vert' do
          subject.display.action_window(window.id, :change_state, 'add', 'maximized_vert')
          sleep 0.25

          window_with_maximized_vert = subject.windows(id: window.id).first
          expect(window_with_maximized_vert.maximized_vertically?).to be_truthy

          subject.move_resize window_with_maximized_vert, a_geometry
          expect(subject.windows(id: window.id).first.maximized_vertically?).to be_falsey
        end

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
