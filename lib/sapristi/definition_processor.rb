# frozen_string_literal: true

module Sapristi
  class DefinitionProcessor
    def initialize(window_manager = WindowManager.new)
      @window_manager = window_manager
    end

    def process_definition(definition)
      window = get_window definition['Title'], definition['Command']
      
      @window_manager.resize(window, definition["H-size"], definition["V-size"])
      @window_manager.move(window, definition["X-position"], definition["Y-position"])
    end

    private
    def get_window(title, command)
    	if title
        windows = @window_manager.find_window(/#{title}/)
        raise Error, "#{windows.size} windows have the same title: #{title}" if windows.size > 1

        window = windows[0]
      end

      window = @window_manager.launch command if window.nil? && command

      raise Error, "Couldn't produce a window for this definition" unless window

      window
    end
  end
end
