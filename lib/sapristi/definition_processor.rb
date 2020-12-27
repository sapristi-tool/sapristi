# frozen_string_literal: true

module Sapristi
  class DefinitionProcessor
    def initialize(window_manager = WindowManager.new, process_manager = NewProcessWindowDetector.new)
      @window_manager = window_manager
      @process_manager = process_manager
      @wait_time = nil
    end

    attr_accessor :wait_time

    def process_definition(definition)
      window = get_window definition.title, definition.command

      @window_manager.move_resize(window,
                                  [definition.x, definition.y,
                                   definition.width, definition.height])
      @window_manager.to_workspace(window, definition.workspace)
      window
    end

    private

    def get_window(title, command)
      (title && find_one_by_title(title)) ||
        (command && @process_manager.detect_window_for_process(command, title)) ||
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
