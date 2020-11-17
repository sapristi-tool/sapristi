module Sapristi
  class DefinitionProcessor
    def initialize(window_manager = WindowManager.new)
      @window_manager = window_manager
    end

    def process_definition(definition)
      if definition['Title']
        windows = @window_manager.find_window(/#{definition["Title"]}/)
        raise Error, "#{windows.size} windows have the same title: #{definition['Title']}" if windows.size > 1

        window = windows[0]
      end

      window = @window_manager.launch definition['Command'] if window.nil? && definition['Command']

      raise Error, "Couldn't produce a window for this definition" unless window

      window
    end
  end
end
