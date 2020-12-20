# frozen_string_literal: true

module Sapristi
  module Linux
    class ProcessManager
      def self.execute_and_detach(cmd, out, err)
        write_log_headers(out, err, cmd)
        process_pid = begin
          Process.spawn(cmd, out: [out, 'a'], err: [err, 'a'])
        rescue StandardError
          raise Error, "Error executing process: #{$ERROR_INFO}"
        end
        ::Sapristi.logger.info "Launch #{cmd.split[0]}, process=#{process_pid}"
        Process.detach process_pid
      end

      def self.write_log_headers(out, err, header)
        [out, err].each { |file_name| write_header(file_name, header) }
      end

      def self.write_header(file_name, header)
        File.open(file_name, 'a') { |file| file.write "\n\n#{header}\n" }
      end

      def self.kill(waiter)
        Process.kill 'KILL', waiter.pid
        # sleep 1 # XLIB error for op code
        raise Error, 'Error executing process, it didn\'t open a window'
      end

      def self.user_pids
        user_id = `id -u`.strip
        `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i)
      end

      def self.cmd_for_pid(pid)
        cmd = "ps -o cmd -p #{pid}"
        line = `#{cmd}`.split("\n")[1]
        raise Error, "No process found pid=#{pid}" unless line

        line
      end
    end
  end
end
