# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

module Sapristi
  RSpec.describe MonitorManager do
    subject { MonitorManager.new }
    let(:a_monitor_name) { 'DP-1' }
    let(:another_monitor_name) { 'HDMI-1' }
    let(:a_monitor) do
      Monitor.new({ id: 0, name: a_monitor_name, main: '*', x: 3840, y: 2160,
        offset_x: 0, offset_y: 0,
        work_area: [100, 200, 400, 600], work_area_height: 400, work_area_width: 300 }.transform_keys(&:to_s))
    end
    let(:main_monitor) { a_monitor }
    let(:another_monitor_offset_x) { 3840 }
    let(:another_monitor_offset_y) { 2000 }
    let(:another_monitor) do
      Monitor.new({ id: 1,
        name: another_monitor_name, main: nil,
        x: 1920, y: 1080,
        offset_x: another_monitor_offset_x, offset_y: another_monitor_offset_y,
        work_area: [
          work_area.x - another_monitor_offset_x,
          work_area.y - another_monitor_offset_y,
          work_area.x + work_area.width - another_monitor_offset_x,
          work_area.y + work_area.height - another_monitor_offset_y
        ],
        work_area_height: work_area.height,
        work_area_width: work_area.width }.transform_keys(&:to_s))
    end
    let(:xrandr_example) do
      %(Monitors: 2
   0: +*#{a_monitor_name} 3840/597x2160/336+0+0  DP-1
   1: +#{another_monitor_name} 1920/509x1080/286+#{another_monitor_offset_x}+#{another_monitor_offset_y}  HDMI-1)
    end

    let(:work_area) do
      OpenStruct.new(x: 100, y: 200, width: 300, height: 400)
    end

    it 'raises an error if xrandr execution fails' do
      allow_any_instance_of(Linux::MonitorManager)
        .to(receive(:list_monitors).and_wrap_original { |_m, *_args| `axrandr --listmonitors` })

      expect { subject.get_monitor_or_main(nil) }.to raise_error(Error, /Error fetching monitor information/)
    end

    context('#get_monitor_or_main') do
      before(:each) do
        allow_any_instance_of(Linux::MonitorManager).to receive(:list_monitors).and_return(xrandr_example)
        allow_any_instance_of(Linux::MonitorManager)
          .to receive(:monitors_work_area).and_return(0 => work_area, 1 => work_area)
      end

      it 'a monitor' do
        expect(subject.get_monitor_or_main(a_monitor_name)).to eq(a_monitor)
      end

      it 'another monitor with offset' do
        expect(subject.get_monitor_or_main(another_monitor_name)).to eq(another_monitor)
      end

      it 'main monitor when monitor name not found' do
        expect(subject.get_monitor_or_main('none')).to eq(main_monitor)
      end

      it 'main monitor when monitor name is nil' do
        expect(subject.get_monitor_or_main(nil)).to eq(main_monitor)
      end
    end
  end
end
