# frozen_string_literal: true

module Sapristi
  class DefinitionProcessor
    def initialize(window_manager = WindowManager.new)
      @window_manager = window_manager
    end

    def process_definition(definition)
      window = get_window definition['Title'], definition['Command']

      @window_manager.resize(window, definition['H-size'], definition['V-size'])
      @window_manager.move(window, definition['X-position'], definition['Y-position'])
    end

    private

    def get_window(title, command)
      (title && find_one_by_title(title)) ||
        (command && @window_manager.launch(command)) ||
        (raise(Error, "Couldn't produce a window for this definition"))
    end

    def find_one_by_title(title)
      windows = @window_manager.find_window(/#{title}/)
      raise Error, "#{windows.size} windows have the same title: #{title}" if windows.size > 1

      if windows.size.eql? 1
        ::Sapristi.logger.info "Found existing window pid=#{windows[0].pid} title=#{windows[0].title}"
      end
      windows[0]
    end
  end
end
