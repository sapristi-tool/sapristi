# frozen_string_literal: true

require 'spec_helper'
require 'shared_examples/percentages'

# rubocop:disable Style/MixinUsage:
include Sapristi
# rubocop:enable Style/MixinUsage:

RSpec.describe DefinitionParser do
  subject { DefinitionParser.new }
  context('error in lines') do
    def create_valid_file_one_line(values)
      definition = build :valid_hash, attrs: values
      build(:valid_csv_file_path, rows: [definition])
    end

    let(:monitor_width) { 1024 }
    let(:monitor_height) { 480 }

    let(:workspaces) do
      [
        OpenStruct.new(current: nil, id: 0),
        OpenStruct.new(current: true, id: 1),
        OpenStruct.new(current: nil, id: 2)
      ]
    end

    let(:monitors) do
      {
        'monitor1' => { 'id' => 0,
                        'main' => '*',
                        'name' => 'monitor1',
                        'x' => monitor_width,
                        'y' => monitor_height,
                        'offset_x' => 0,
                        'offset_y' => 0,
                        'work_area' => [70, 27, monitor_width - 70, monitor_height - 27],
                        'work_area_width' => monitor_width - 70,
                        'work_area_height' => monitor_height - 27 },

        'monitor2' => { 'id' => 1,
                        'main' => nil,
                        'name' => 'monitor2',
                        'x' => 1920,
                        'y' => 1080,
                        'offset_x' => 0,
                        'offset_y' => 0,
                        'work_area' => [0, 0, 1920, 1080],
                        'work_area_width' => 1920,
                        'work_area_height' => 1080 }
      }
    end

    before(:each) do
      allow_any_instance_of(MonitorManager).to receive(:monitors).and_return(monitors)
      allow_any_instance_of(WindowManager).to receive(:workspaces).and_return(workspaces)
    end

    it 'when headers' do
      definition_attrs = build(:valid_hash, attrs: { invalid_header: nil })
      expect { subject.parse definition_attrs }.to raise_error(Error, /Invalid configuration file: invalid headers/)
    end

    it 'when no window and no command specified' do
      definition_attrs = build(:valid_hash, attrs: { 'Command' => nil, 'Title' => nil })
      expect { subject.parse definition_attrs }.to raise_error(Error, /No command or window title specified/)
    end

    it 'when any of the geometry values is not defined' do
      %w[H-size V-size X-position Y-position].each do |key|
        definition_attrs = build(:valid_hash, attrs: { key => nil })
        expect { subject.parse definition_attrs }.to raise_error(Error, /No #{key} specified/)
      end
    end

    it 'when fixed x > monitor width' do
      definition_attrs = build(:valid_hash, attrs: { 'X-position' => monitor_width })

      valid = "0..#{monitor_width - 1}"
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /x=#{monitor_width} is outside of monitor width dimension=#{valid}/)
    end

    it 'when fixed y > monitor length' do
      definition_attrs = build(:valid_hash, attrs: { 'Y-position' => monitor_height })

      valid = "0..#{monitor_height - 1}"
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /y=#{monitor_height} is outside of monitor height dimension=#{valid}/)
    end

    it 'when fixed x < 0' do
      x_pos = -1
      definition_attrs = build(:valid_hash, attrs: { 'X-position' => x_pos })

      expect { subject.parse definition_attrs }
        .to raise_error(Error, /x=#{x_pos} is outside of monitor width dimension=0..#{monitor_width - 1}/)
    end

    it 'when fixed y < 0' do
      y_pos = -1
      definition_attrs = build(:valid_hash, attrs: { 'Y-position' => y_pos })

      expect { subject.parse definition_attrs }
        .to raise_error(Error, /y=#{y_pos} is outside of monitor height dimension=0..#{monitor_height - 1}/)
    end

    let(:x_pos) { monitor_width / 2 }
    let(:y_pos) { monitor_height / 2 }
    let(:x_size) { 1 + monitor_width / 2 }
    let(:y_size) { 1 + monitor_height / 2 }
    let(:dimensions_x) { "\\[#{x_pos}, #{x_pos + x_size}\\]" }
    let(:dimensions_y) { "\\[#{y_pos}, #{y_pos + y_size}\\]" }

    it 'when x + width > monitor width' do
      definition_attrs = build(:valid_hash, attrs: { 'X-position' => x_pos, 'H-size' => x_size })

      valid = "\\[0..#{monitor_width - 1}\\]"
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /window x dimensions: #{dimensions_x} exceeds monitor width #{valid}/)
    end

    it 'when y + length > monitor length' do
      definition_attrs = build(:valid_hash, attrs: { 'Y-position' => y_pos, 'V-size' => y_size })

      valid = "\\[0..#{monitor_height - 1}\\]"
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /window y dimensions: #{dimensions_y} exceeds monitor height #{valid}/)
    end

    it 'when witdh < 50' do
      definition_attrs = build(:valid_hash, attrs: { 'H-size' => 49 })
      expect { subject.parse definition_attrs }.to raise_error(Error, /window x size=49 less than 50/)
    end

    it 'when length < 50' do
      definition_attrs = build(:valid_hash, attrs: { 'V-size' => 49 })
      expect { subject.parse definition_attrs }.to raise_error(Error, /window y size=49 less than 50/)
    end

    context('percentages') do
      include_examples 'geometry percentage', 'X-position', 0
      include_examples 'geometry percentage', 'Y-position', 0
      include_examples 'geometry percentage', 'H-size'
      include_examples 'geometry percentage', 'V-size'
    end

    it 'when no command and no title specified' do
      definition_attrs = build(:valid_hash, attrs: { 'Command' => nil, 'Title' => nil })
      expect { subject.parse definition_attrs }.to raise_error(Error, /No command or window title specified/)
    end

    it 'when monitor < 0' do
      definition_attrs = build(:valid_hash, attrs: { 'Monitor' => -1 })
      expect { subject.parse definition_attrs }.to raise_error(Error, /Invalid monitor=-1/)
    end

    it 'when workspace < 0' do
      definition_attrs = build(:valid_hash, attrs: { 'Workspace' => -1 })
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /invalid workspace=-1 valid=0..#{last_workspace_id}/)
    end

    let(:last_workspace_id) { WindowManager.new.workspaces.size - 1 }
    let(:current_workspace_id) { WindowManager.new.workspaces.find(&:current).id }

    it 'when workspace id > last workspace id' do
      definition_attrs = build(:valid_hash, attrs: { 'Workspace' => last_workspace_id + 1 })
      expect { subject.parse definition_attrs }
        .to raise_error(Error, /invalid workspace=#{last_workspace_id + 1} valid=0..#{last_workspace_id}/)
    end

    it 'when workspace is not specified use current' do
      definition_attrs = build(:valid_hash, attrs: { 'Workspace' => nil })
      expect(subject.parse(definition_attrs).workspace).to eq(current_workspace_id)
    end

    it 'numeric fields are integers' do
      definition = Definition.new build(:valid_hash)

      %w[x_position y_position h_size v_size workspace].each do |field|
        expect(definition.send(field)).to be_instance_of Integer
      end
    end
  end
end
