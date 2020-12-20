# frozen_string_literal: true

require 'forwardable'

module Sapristi
  class WindowManager
    extend Forwardable

    def initialize
      @display = OSFactory.new.window_manager
    end

    def_delegators :@display, :windows, :close, :workspaces, :move_resize, :resize, :move, :to_workspace

    def find_window(title_regex)
      @display.windows title: title_regex
    end

    def find_workspace_or_current(id)
      return workspaces.find(&:current).id unless id

      return id if workspace?(id)

      available = 0..(workspaces.size - 1)
      raise Error, "invalid workspace=#{id} valid=#{available}" unless available.include? id
    end

    private

    def workspace?(id)
      workspaces.find { |workspace| workspace.id.eql? id }
    end
  end
end
