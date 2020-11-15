require "spec_helper"

include Sapristi

RSpec.describe MonitorManager do
	let(:under_test) { MonitorManager.new }

	it 'raises an error if xrandr execution fails' do
		expect { under_test.get_monitor(nil) }.to raise_error(Error, /Error fetching monitor information/)
	end
end