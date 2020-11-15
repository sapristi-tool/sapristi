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
			{"Title" => "some title", "Command" => nil, "Monitor" => 6, "X-position" => 7, "Y-position" => 8, "H-size" => 9, "V-size" => 10, "Workspace" => 11, "Line" => 1},
			{"Title" => "some title", "Command" => nil, "Monitor" => 0, "X-position" => "10%", "Y-position" => "20%", "H-size" => "30%", "V-size" => "40%", "Workspace" => 11, "Line" => 1}
			]
	end


	it 'raises an error when configuration file is not found' do
		expect { under_test.load(non_existing_file) }.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
	end

	it 'raises an error when csv format is invalid' do
		expect { under_test.load(invalid_csv) }.to raise_error(Error, /Invalid configuration file: headers/)
	end

	context 'configuration file' do
		let(:content) { under_test.load(valid_csv) }

		let(:xrandr_example) {
%Q{Monitors: 2
 0: +*some 3840/597x2160/336+0+0  DP-1
 1: +another 1920/509x1080/286+3840+0  HDMI-1
}
	}

		it 'line field is added' do
			expect(content[0]["Line"]).to eql(0)
		end

		it 'numeric fields are integers' do
			%w(Line X-position Y-position H-size V-size Workspace).each do |field|
				expect(content[1][field]).not_to be_nil
				expect(content[1][field]).to be_instance_of Integer
			end
		end

		it 'apply percentage using monitor dimensions position fields' do
			translations = { "H-size" => "x", "V-size" => "y", "X-position" => "x", "Y-position" => "y" }

			

			%w(X-position Y-position H-size V-size).each do |field|
				monitor = { id: 0, name: "some", main: "*", x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s)
				allow_any_instance_of(MonitorManager).to receive(:list_monitors).and_return(xrandr_example)

				expect(content[2][field]).to be ( (valid_csv_definitions[2][field][0..-2].to_i / 100.0) * monitor[translations[field]]).to_i
			end
		end
	end
end