# frozen_string_literal: true

require 'wmctrl'

module Sapristi
  module Linux
    class WindowManager
      def initialize
        @display = WMCtrl.display
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
        sleep 1
      end

      def windows(args = {})
        @display.windows args
      end

      def workspaces
        @display.desktops
      end

      GRAVITY = 0
      TIME_TO_APPLY_DIMENSIONS = 0.5

      def move_resize(window, geometry)
        @display.action_window(window.id, :move_resize, GRAVITY, *geometry)
        sleep TIME_TO_APPLY_DIMENSIONS
      end
    end
  end
end
