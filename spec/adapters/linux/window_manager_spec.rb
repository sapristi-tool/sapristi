# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  module Linux
    RSpec.describe WindowManager do
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
  end
end
