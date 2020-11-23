# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe MonitorManager do
    subject { MonitorManager.new }
    let(:a_monitor_name) { 'DP-1' }
    let(:another_monitor_name) { 'HDMI-1' }
    let(:a_monitor) do
      { id: 0, name: a_monitor_name, main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s)
    end
    let(:main_monitor) { a_monitor }
    let(:another_monitor) do
      { id: 1,
        name: another_monitor_name, main: nil, x: 1920, y: 1080, offset_x: 3840, offset_y: 0 }.transform_keys(&:to_s)
    end
    let(:xrandr_example) do
      %(Monitors: 2
   0: +*#{a_monitor_name} 3840/597x2160/336+0+0  DP-1
   1: +#{another_monitor_name} 1920/509x1080/286+3840+0  HDMI-1)
    end

    it 'raises an error if xrandr execution fails' do
      allow_any_instance_of(LinuxXrandrAdapter)
        .to(receive(:list_monitors).and_wrap_original { |_m, *_args| `axrandr --listmonitors` })

      expect { subject.get_monitor(nil) }.to raise_error(Error, /Error fetching monitor information/)
    end

    context('#get_monitor') do
      before(:each) { allow_any_instance_of(LinuxXrandrAdapter).to receive(:list_monitors).and_return(xrandr_example) }

      it 'a monitor' do
        expect(subject.get_monitor(a_monitor_name)).to eq(a_monitor)
      end

      it 'another monitor' do
        expect(subject.get_monitor(another_monitor_name)).to eq(another_monitor)
      end

      it 'main monitor when monitor name not found' do
        expect(subject.get_monitor('none')).to eq(main_monitor)
      end

      it 'main monitor when monitor name is nil' do
        expect(subject.get_monitor(nil)).to eq(main_monitor)
      end
    end
  end
end
