# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe DefinitionProcessor do
    subject { DefinitionProcessor.new }
    let(:command) { 'sol' }

    context('fetch window') do
      it('launches command when window title not specified') do
        window_detector = spy('window_detector')

        definition = build(:a_valid_definition, attrs: { 'Command' => command, 'Title' => nil })
        DefinitionProcessor.new(spy('window_manager'), window_detector).process_definition(definition)

        expect(window_detector).to have_received(:detect_window_for_process).with(command)
      end

      let(:window_manager) { spy('window_manager') }
      let(:window) { double('window', pid: 1, title: 'title') }
      let(:definition) { build(:a_valid_definition, attrs: { 'Command' => command, 'Title' => 'Klondike' }) }

      it('uses window when found by title') do
        allow(window_manager).to receive(:find_window).with(/Klondike/).and_return([window])

        DefinitionProcessor.new(window_manager).process_definition(definition)

        expect(window_manager).to have_received(:move_resize).with(window, any_args)
      end

      context('raises an error') do
        it('when window with title is not present and command not supplied') do
          expect do
            definition = build(:a_valid_definition, attrs: { 'Command' => nil, 'Title' => 'non existing window title' })
            subject.process_definition(definition)
          end.to raise_error Error, "Couldn't produce a window for this definition"
        end

        let(:launcher) { NewProcessWindowDetector.new }
        let!(:a_window) { launcher.detect_window_for_process command }
        let!(:another_window) { launcher.detect_window_for_process command }
        it('when more than one window have the same title') do
          duplicated_title = /Klondike/
          expect do
            definition = build(:a_valid_definition, attrs: { 'Command' => nil, 'Title' => duplicated_title })
            subject.process_definition(definition)
          end.to raise_error Error, "2 windows have the same title: #{duplicated_title}"
        end
        after(:each) do
          [a_window, another_window].each { |window| WindowManager.new.close(window) }
        end
      end
    end

    context 'manipulate window' do
      let(:window) { double('window') }
      let(:window_manager) { spy('window_manager') }
      subject do
        manager = DefinitionProcessor.new(window_manager)
        allow(manager).to receive(:get_window).and_return(window)

        manager
      end
      let(:x_position) { 1 }
      let(:y_position) { 2 }
      let(:size_x) { 3 }
      let(:size_y) { 4 }

      let(:definition) do
        Definition.new({ 'Command' => command, 'X-position' => x_position, 'Y-position' => y_position,
                         'H-size' => size_x, 'V-size' => size_y })
      end

      it 'move and resize window' do
        subject.process_definition(definition)

        expect(window_manager).to have_received(:move_resize).with(window, x_position, y_position, size_x, size_y)
      end
    end
  end
end
