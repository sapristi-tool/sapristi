# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe DefinitionProcessor do
    subject { DefinitionProcessor.new }
    let(:command) { 'sol' }

    context('fetch window') do
      it('launches command when window title not specified') do
        window_manager = spy('window_manager')

        definition = build(:a_valid_definition, attrs: { 'Command' => command, 'Title' => nil })
        DefinitionProcessor.new(window_manager).process_definition(definition)

        expect(window_manager).to have_received(:launch).with(command)
      end

      it('uses window when found by title') do
        window_manager = spy('window_manager')
        window = double('window', pid: 1, title: 'title')
        allow(window_manager).to receive(:find_window).with(/Klondike/).and_return([window])

        definition = build(:a_valid_definition, attrs: { 'Command' => command, 'Title' => 'Klondike' })
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

        it('when more than one window have the same title') do
          window_manager = WindowManager.new
          a_window = window_manager.launch command
          another_window = window_manager.launch command

          duplicated_title = /Klondike/
          expect do
            definition = build(:a_valid_definition, attrs: { 'Command' => nil, 'Title' => duplicated_title })
            subject.process_definition(definition)
          end.to raise_error Error, "2 windows have the same title: #{duplicated_title}"
        ensure
          window_manager.close(a_window) if a_window
          window_manager.close(another_window) if another_window
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
