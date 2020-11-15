require "spec_helper"

include Sapristi

RSpec.describe MonitorManager do
	let(:under_test) { MonitorManager.new }
	let(:a_monitor_name) { "DP-1" }
	let(:a_monitor) { { id: 0, name: "DP-1", main: "*", x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s) }
	let(:xrandr_example) {
%Q{Monitors: 2
 0: +*DP-1 3840/597x2160/336+0+0  DP-1
 1: +HDMI-1 1920/509x1080/286+3840+0  HDMI-1
}
	}

	it 'raises an error if xrandr execution fails' do
		expect(under_test).to receive(:list_monitors).and_wrap_original {|m, *args| `axrandr --listmonitors` }

		expect { under_test.get_monitor(nil) }.to raise_error(Error, /Error fetching monitor information/)
	end

	it 'get a monitor' do
		expect(under_test).to receive(:list_monitors).and_return(xrandr_example)

		expect(under_test.get_monitor(a_monitor_name)).to eql(a_monitor)
	end
end