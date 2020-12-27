# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe MonitorManager do
    subject { MonitorManager.new }

    it 'raises an error if xrandr execution fails' do
      allow_any_instance_of(Linux::MonitorManager)
        .to(receive(:list_monitors).and_wrap_original { |_m, *_args| `axrandr --listmonitors` })

      expect { subject.get_monitor_or_main(nil) }.to raise_error(Error, /Error fetching monitor information/)
    end

    context('#get_monitor_or_main') do
      before(:each) do
        allow_any_instance_of(Linux::MonitorManager).to receive(:list_monitors).and_return(build(:xrandr_example))
        allow_any_instance_of(Linux::MonitorManager)
          .to receive(:monitors_work_area).and_return(0 => build(:work_area), 1 => build(:work_area))
      end

      let(:main_monitor) { Monitor.new build(:a_monitor) }

      it 'a monitor' do
        expect(subject.get_monitor_or_main('a-monitor')).to eq(Monitor.new(build(:a_monitor)))
      end

      it 'another monitor with offset' do
        expect(subject.get_monitor_or_main('another-monitor')).to eq(Monitor.new(build(:another_monitor)))
      end

      it 'main monitor when monitor name not found' do
        expect(subject.get_monitor_or_main('none')).to eq(main_monitor)
      end

      it 'main monitor when monitor name is nil' do
        expect(subject.get_monitor_or_main(nil)).to eq(main_monitor)
      end

      it 'shows monitor info' do
        expected = 'Monitors: 2
0 main a-monitor 1000x2000 workarea[x=100, y=200, width=300, height=400]
1      another-monitor 3000x4000 workarea[x=100, y=200, width=300, height=400]
'
        expect { subject.show_monitors }.to output(expected).to_stdout
      end
    end
  end
end
