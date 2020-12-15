# frozen_string_literal: true

module Sapristi
  module Linux
    class ProcessManager
      def execute_and_detach(cmd)
        process_pid = begin
          Process.spawn(cmd)
        rescue StandardError
          raise Error, "Error executing process: #{$ERROR_INFO}"
        end
        ::Sapristi.logger.info "Launch #{cmd.split[0]}, process=#{process_pid}"
        Process.detach process_pid
      end

      def kill(waiter)
        Process.kill 'KILL', waiter.pid
        # sleep 1 # XLIB error for op code
        raise Error, 'Error executing process, it didn\'t open a window'
      end

      def user_pids
        user_id = `id -u`.strip
        `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
      end

      def cmd_for_pid(pid)
        cmd = "ps -o cmd -p #{pid}"
        line = `#{cmd}`.split("\n")[1]
        raise Error, "No process found pid=#{pid}" unless line

        line
      end
    end
  end
end
