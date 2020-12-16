# frozen_string_literal: true

require 'wmctrl'

module Sapristi
  module Linux
    class WindowManager
      def initialize(display = WMCtrl.display)
        @display = display
      end

      attr_reader :display

      def close(window)
        @display.action_window(window.id, :close)

        #
        # sleep to allow a Graceful Dead to the window process
        #
        # X Error of failed request:  BadWindow (invalid Window parameter)
        #   Major opcode of failed request:  20 (X_GetProperty)
        #   Resource id in failed request:  0x2200008
        #   Serial number of failed request:  1095
        #   Current serial number in output stream:  1095
        sleep TIME_TO_APPLY_DIMENSIONS
      end

      def windows(args = {})
        @display.windows args
      end

      def workspaces
        @display.desktops
      end

      GRAVITY = 0
      TIME_TO_APPLY_DIMENSIONS = 0.25

      def move_resize(window, geometry)
        remove_extended_hints(window) if window.maximized_horizontally? || window.maximized_vertically?
        @display.action_window(window.id, :move_resize, GRAVITY, *geometry)
        sleep TIME_TO_APPLY_DIMENSIONS
      end

      EXTENDED_HINTS = %w[maximized_vert maximized_horz].freeze

      def remove_extended_hints(window)
        display.action_window(window.id, :change_state, 'remove', *EXTENDED_HINTS)
      end
    end
  end
end
