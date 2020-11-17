# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe DefinitionProcessor do
    it('launches command when window title not specified') do
      window_manager = spy('window_manager')
      command = 'sol'
      DefinitionProcessor.new(window_manager).process_definition({ 'Command' => command })

      expect(window_manager).to have_received(:launch).with(command)
    end

    it('throws an error if window with title is not present and command not supplied') do
      expect do
        DefinitionProcessor.new.process_definition({ 'Title' => 'non existing window title', 'Command' => nil })
      end.to raise_error Error, "Couldn't produce a window for this definition"
    end

    it('throws an error if more than one window have the same title') do
      window_manager = WindowManager.new
      window1 = window_manager.launch 'sol'
      window2 = window_manager.launch 'sol'

      duplicated_title = /Klondike/
      expect do
        DefinitionProcessor.new.process_definition({ 'Title' => duplicated_title, 'Command' => nil })
      end.to raise_error Error, "2 windows have the same title: #{duplicated_title}"
    ensure
      window_manager.close(window1) if window1
      window_manager.close(window2) if window2
    end
  end
end
