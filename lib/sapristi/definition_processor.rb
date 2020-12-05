# frozen_string_literal: true

module Sapristi
  class DefinitionProcessor
    def initialize(window_manager = WindowManager.new)
      @window_manager = window_manager
    end

    def process_definition(definition)
      title = definition.title
      command = definition.command
      x_position = definition.x_position
      y_position = definition.y_position
      width = definition.h_size
      height = definition.v_size

      window = get_window title, command

      @window_manager.move_resize(window, x_position, y_position, width, height)
    end

    private

    def get_window(title, command)
      (title && find_one_by_title(title)) ||
        (command && @window_manager.launch(command)) ||
        raise(Error, "Couldn't produce a window for this definition")
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
