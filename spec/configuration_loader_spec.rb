# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'ostruct'

module Sapristi
  RSpec.describe ConfigurationLoader do
    subject { ConfigurationLoader.new }

    let(:non_existing_file) do
      '/tmp/non_existent_file_path.csv'
    end

    let(:invalid_csv) do
      file = Tempfile.new('foo')
      file.write('hello world')
      file.close
      file.path
    end

    let(:valid_headers) { %w[Title Command Monitor X-position Y-position H-size V-size Workspace] }
    let(:separator) { ',' }

    let(:valid_csv) do
      file = Tempfile.new('bar')
      file.write(valid_headers.join(separator))
      file.write "\n"
      valid_csv_definitions.each do |valid_definition|
        file.write valid_headers.map { |header| valid_definition[header] }.join(separator)
        file.write "\n"
      end
      file.close

      file.path
    end

    let(:valid_csv_definitions) do
      [
        { 'Title' => nil, 'Command' => 'some', 'Monitor' => nil, 'X-position' => 1,
          'Y-position' => 2, 'H-size' => 300, 'V-size' => 400, 'Workspace' => 0 },
        { 'Title' => 'some title', 'Command' => nil, 'Monitor' => 6, 'X-position' => 7,
          'Y-position' => 8, 'H-size' => 900, 'V-size' => 100, 'Workspace' => 0 },
        { 'Title' => 'some title', 'Command' => nil, 'Monitor' => 0, 'X-position' => '10%',
          'Y-position' => '20%', 'H-size' => '30%', 'V-size' => '40%', 'Workspace' => nil }
      ]
    end

    context('#load') do
      context('raises an error') do
        it 'when configuration file is not found' do
          expect do
            subject.load(non_existing_file)
          end.to raise_error(Error, /Configuration file not found: #{non_existing_file}/)
        end

        it 'when csv is empty' do
          empty_file = Tempfile.create('foo')
          empty_file.close

          expect { subject.load(empty_file) }.to raise_error(Error, /Invalid configuration file: Empty file/)
        end

        it 'when csv format is invalid' do
          expect { subject.load(invalid_csv) }.to raise_error(Error, /Invalid configuration file: invalid headers/)
        end

        context('error in lines') do
          def create_valid_file_one_line(values)
            file = '/tmp/mock_conf.csv'
            File.delete file if File.exist? file

            definition = valid_csv_definitions[0].merge(values)
            subject.save(file, [definition])
            file
          end

          let(:monitor_width) { 1024 }
          let(:monitor_height) { 480 }
          let(:xrandr_example) do
            %(Monitors: 2
   0: +*monitor1 #{monitor_width}/597x#{monitor_height}/336+0+0  DP-1
   1: +monitor2 1920/509x1080/286+3840+0  HDMI-1)
          end

          let(:some_monitors) do
            [
              OpenStruct.new(current: nil, id: 0),
              OpenStruct.new(current: true, id: 1),
              OpenStruct.new(current: nil, id: 2)
            ]
          end

          before(:each) do
            allow_any_instance_of(MonitorManager).to receive(:list_monitors).and_return(xrandr_example)
            allow_any_instance_of(WindowManager).to receive(:workspaces).and_return(some_monitors)
          end

          it 'when no window and no command specified' do
            file = create_valid_file_one_line('Command' => nil, 'Title' => nil)
            expect { subject.load file }.to raise_error(Error, /No command or window title specified/)
          end

          it 'when any of the geometry values is not defined' do
            %w[H-size V-size X-position Y-position].each do |key|
              file = create_valid_file_one_line(key => nil)
              expect { subject.load file }.to raise_error(Error, /No #{key} specified/)
            end
          end

          it 'when fixed x > monitor width' do
            file = create_valid_file_one_line('X-position' => monitor_width)

            valid = "0..#{monitor_width - 1}"
            expect { subject.load file }
              .to raise_error(Error, /x=#{monitor_width} is outside of monitor width dimension=#{valid}/)
          end

          it 'when fixed y > monitor length' do
            file = create_valid_file_one_line('Y-position' => monitor_height)

            valid = "0..#{monitor_height - 1}"
            expect { subject.load file }
              .to raise_error(Error, /y=#{monitor_height} is outside of monitor height dimension=#{valid}/)
          end

          it 'when fixed x < 0' do
            x = -1
            file = create_valid_file_one_line('X-position' => x)

            expect { subject.load file }
              .to raise_error(Error, /x=#{x} is outside of monitor width dimension=0..#{monitor_width - 1}/)
          end

          it 'when fixed y < 0' do
            y = -1
            file = create_valid_file_one_line('Y-position' => y)

            expect { subject.load file }
              .to raise_error(Error, /y=#{y} is outside of monitor height dimension=0..#{monitor_height - 1}/)
          end

          it 'when x + width > monitor width' do
            x = monitor_width / 2
            x_size = 1 + monitor_width / 2
            file = create_valid_file_one_line('X-position' => x, 'H-size' => x_size)

            dimensions = "\\[#{x}, #{x + x_size}\\]"
            valid = "\\[0..#{monitor_width - 1}\\]"
            expect { subject.load file }
              .to raise_error(Error, /window x dimensions: #{dimensions} exceeds monitor width #{valid}/)
          end

          it 'when y + length > monitor length' do
            y = monitor_height / 2
            y_size = 1 + monitor_height / 2
            file = create_valid_file_one_line('Y-position' => y, 'V-size' => y_size)

            dimensions = "\\[#{y}, #{y + y_size}\\]"
            valid = "\\[0..#{monitor_height - 1}\\]"
            expect { subject.load file }
              .to raise_error(Error, /window y dimensions: #{dimensions} exceeds monitor height #{valid}/)
          end

          it 'when witdh < 50' do
            file = create_valid_file_one_line('H-size' => 49)
            expect { subject.load file }.to raise_error(Error, /window x size=49 less than 50/)
          end

          it 'when length < 50' do
            file = create_valid_file_one_line('V-size' => 49)
            expect { subject.load file }.to raise_error(Error, /window y size=49 less than 50/)
          end

          context('percentages') do
            RSpec.shared_examples 'geometry percentage' do |field|
              it "when #{field} percentage x < 5" do
                raw = '4%'
                file = create_valid_file_one_line(field => raw)
                expect { subject.load file }
                  .to raise_error(Error, /#{field} percentage is invalid=#{raw}, valid=5%-100%/)
              end

              it "when #{field} percentage x > 100" do
                raw = '101%'
                file = create_valid_file_one_line(field => raw)
                expect { subject.load file }
                  .to raise_error(Error, /#{field} percentage is invalid=#{raw}, valid=5%-100%/)
              end
            end

            include_examples 'geometry percentage', 'X-position'
            include_examples 'geometry percentage', 'Y-position'
            include_examples 'geometry percentage', 'H-size'
            include_examples 'geometry percentage', 'V-size'
          end

          it 'when no command and no title specified' do
            file = create_valid_file_one_line('Command' => nil, 'Title' => nil)
            expect { subject.load file }.to raise_error(Error, /No command or window title specified/)
          end

          it 'when monitor < 0' do
            file = create_valid_file_one_line('Monitor' => -1)
            expect { subject.load file }.to raise_error(Error, /Invalid monitor=-1/)
          end

          it 'when workspace < 0' do
            last_workspace_id = WindowManager.new.workspaces.size - 1
            file = create_valid_file_one_line('Workspace' => -1)
            expect { subject.load file }.to raise_error(Error, /invalid workspace=-1 valid=0..#{last_workspace_id}/)
          end

          it 'when workspace id > last workspace id' do
            last_workspace_id = WindowManager.new.workspaces.size - 1

            file = create_valid_file_one_line('Workspace' => last_workspace_id + 1)
            expect { subject.load file }
              .to raise_error(Error, /invalid workspace=#{last_workspace_id + 1} valid=0..#{last_workspace_id}/)
          end

          it 'when workspace is not specified use current' do
            current_workspace_id = WindowManager.new.workspaces.find(&:current).id
            file = create_valid_file_one_line('Workspace' => nil)
            expect(subject.load(file)[0]['Workspace']).to eq(current_workspace_id)
          end
        end
      end
    end

    context('#save') do
      context('raises and error') do
        it 'when creating an empty configuration on an existing file' do
          file = Tempfile.new('foo')
          file.close

          expect do
            subject.create_empty_configuration file.path
          end.to raise_error Error, /Trying to write empty configuration on existing file #{file.path}/
        ensure
          file.unlink
        end

        it 'when saving configuration on an existing file' do
          file = Tempfile.new('foo')
          file.close

          expect do
            subject.save file.path, nil
          end.to raise_error Error, /Trying to write configuration on existing file #{file.path}/
        ensure
          file.unlink
        end
      end

      it 'saves definitions' do
        file = Tempfile.new('foo')
        file.close
        file_path = file.path
        file.unlink

        subject.save file_path, valid_csv_definitions

        expect(subject.load(file_path)).to eq(valid_csv_definitions.map { |d| subject.send :normalize, d })
      end

      it 'writes empty configuration' do
        file = Tempfile.new('foo')
        file.close
        file_path = file.path
        file.unlink

        subject.create_empty_configuration file_path
        expect(File.read(file_path)).to eql subject.valid_headers.join(ConfigurationLoader::SEPARATOR)
      end
    end

    context 'configuration file' do
      let(:content) { subject.load(valid_csv) }

      let(:xrandr_example) do
        %(Monitors: 2
	 0: +*some 3840/597x2160/336+0+0  DP-1
	 1: +another 1920/509x1080/286+3840+0  HDMI-1)
      end

      it 'numeric fields are integers' do
        %w[X-position Y-position H-size V-size Workspace].each do |field|
          expect(content[1][field]).not_to be_nil
          expect(content[1][field]).to be_instance_of Integer
        end
      end

      it 'apply percentage using monitor dimensions position fields' do
        translations = { 'H-size' => 'x', 'V-size' => 'y', 'X-position' => 'x', 'Y-position' => 'y' }

        %w[X-position Y-position H-size V-size].each do |field|
          monitor = { id: 0, name: 'some',
                      main: '*', x: 3840, y: 2160, offset_x: 0, offset_y: 0 }.transform_keys(&:to_s)
          allow_any_instance_of(MonitorManager).to receive(:list_monitors).and_return(xrandr_example)

          expected = ((valid_csv_definitions[2][field][0..-2].to_i / 100.0) * monitor[translations[field]]).to_i
          expect(content[2][field]).to be expected
        end
      end
    end
  end
end
