require "spec_helper"
require "tempfile"

include Sapristi

RSpec.describe ConfigurationLoader do
	let(:under_test) { ConfigurationLoader.new }
	
	let(:non_existing_file) do
		"/tmp/non_existent_file_path.csv"
	end

	let(:invalid_csv) {
		file = Tempfile.new('foo')
		file.write("hello world")
		file.close
		file.path
	}


	it 'raises an error when configuration file is not found' do
		expect { under_test.load(non_existing_file) }.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
	end

	it 'raises an error when csv format is invalid' do
		expect { under_test.load(invalid_csv) }.to raise_error(Error, /Invalid configuration file: headers/)
	end
end