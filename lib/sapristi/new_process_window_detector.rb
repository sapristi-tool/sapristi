# frozen_string_literal: true

module Sapristi
  class NewProcessWindowDetector
    def initialize
      @display = WMCtrl.display
      @previous_windows_ids = @display.windows.map { |window| window[:id] }
      @previous_pids = NewProcessWindowDetector.user_pids
    end

    attr_reader :previous_windows_ids, :previous_pids

    def detect_window_for_process(waiter, timeout_in_seconds)
      start_time = Time.now
      while Time.now - start_time < timeout_in_seconds && waiter.alive?
        process_window = detect_new_windows.find { |window| window.pid.eql? waiter.pid }

        break if process_window

        sleep 0.5
      end

      raise Error, 'Error executing process, is dead' unless waiter.alive?

      process_window
    end

    private

    def self.user_pids
      user_id = `id -u`.strip
      `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
    end

    def detect_new_windows
      new_windows = @display.windows.filter { |window| new_window?(window) }

      new_windows.each { |window| ::Sapristi.logger.debug "  Found new window=#{window.pid}: #{window.title}" }
    end

    def new_window?(window)
      !previous_pids.include?(window.pid) && !previous_windows_ids.include?(window.id)
    end
  end
end
