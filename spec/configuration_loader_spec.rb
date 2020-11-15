require "spec_helper"
require "tempfile"

include Sapristi

RSpec.describe ConfigurationLoader do
	let(:under_test) { ConfigurationLoader.new }
	
	let(:non_existing_file) do
		"/tmp/non_existent_file_path.csv"
	end

	let(:invalid_csv) do
		file = Tempfile.new('foo')
		file.write("hello world")
		file.close
		file.path
	end

	let(:valid_headers) { %w(Title Command Monitor X-position Y-position H-size V-size Workspace) }
	let(:separator) { ","}

	let(:valid_csv) do
		file = Tempfile.new('bar')
		file.write(valid_headers.join(separator))
		file.write "\n"
		valid_csv_definitions.each do |valid_definition|
			file.write valid_headers.map {|header| valid_definition[header]}.join(separator)
			file.write "\n"
		end
		file.close

		file.path
	end

	let(:valid_csv_definitions) do
		[
			{"Title" => nil, "Command" => "some", "Monitor" => nil, "X-position" => 1, "Y-position" => 2, "H-size" => 3, "V-size" => 4, "Workspace" => 5, "Line" => 0},
			{"Title" => "some title", "Command" => nil, "Monitor" => 6, "X-position" => 7, "Y-position" => 8, "H-size" => 9, "V-size" => 10, "Workspace" => 11, "Line" => 1}
			]
	end


	it 'raises an error when configuration file is not found' do
		expect { under_test.load(non_existing_file) }.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
	end

	it 'raises an error when csv format is invalid' do
		expect { under_test.load(invalid_csv) }.to raise_error(Error, /Invalid configuration file: headers/)
	end

	it 'reads valid configuration file' do
		expect(under_test.load(valid_csv)).to eql(valid_csv_definitions)
	end
end