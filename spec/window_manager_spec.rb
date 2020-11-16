require "spec_helper"

include Sapristi


RSpec.describe WindowManager do
	let(:under_test) { WindowManager.new }

	it('fetch open windows returns same result as command line wmctrl') do
		expected = `wmctrl -l`.split("\n").map {|w| w.split[0].to_i(16) }
		actual = under_test.windows.map(&:id)
		
		expect(actual).to contain_exactly(*expected)
	end
end