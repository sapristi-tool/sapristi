require "spec_helper"
require "tempfile"

include Sapristi

RSpec.describe ConfigurationLoader do
	let(:under_test) { ConfigurationLoader.new }
	let(:non_existing_file) do
		"/tmp/non_existent_file_path.csv"
	end
	it 'raises an error when configuration file is not found' do
		expect { under_test.load(non_existing_file) }.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
	end
end