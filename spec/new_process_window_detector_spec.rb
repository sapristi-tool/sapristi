# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe NewProcessWindowDetector do
    subject { NewProcessWindowDetector.new }

    let(:timeout) { 5 }
    before(:each) do
      @waiters = []
      @windows = []
    end

    after(:each) do
      @windows.compact.each { |w| WindowManager.new.close w }
      @waiters.each do |waiter|
        Process.kill(9, waiter.pid) if waiter.alive?
        sleep 0.25
      rescue StandardError => e
        puts e
      end
    end

    context('New process per window') do
      let(:waiter) do
        pid = Process.spawn 'sol'
        waiter = Process.detach pid
        @waiters.push waiter
        waiter
      end

      it 'detects window for new process' do
        actual_window = subject.detect_window_for_process 'sol', timeout
        @windows.push actual_window

        expect(actual_window).not_to be_nil
      end

      it 'window has the same pid as initial process' do
        actual_window = subject.detect_window_for_process 'sol', timeout
        @windows.push actual_window

        expect(Linux::ProcessManager.new.cmd_for_pid(actual_window.pid)).to eq('sol')
      end
    end

    context('Same process spawns several children/windows') do
      def new_window
        pid = Process.spawn 'gedit --new-window'
        waiter = Process.detach pid
        @waiters.push waiter
        waiter
      end

      it 'detects two windows with same parent process' do
        first_window = subject.detect_window_for_process 'gedit --new-window', timeout
        @windows.push first_window

        expect(first_window).not_to be_nil

        second_window = subject.detect_window_for_process 'gedit --new-window', timeout
        @windows.push second_window

        expect(second_window).not_to be_nil

        expect(first_window.id).not_to eq(second_window.id)
      end
    end

    context('#detect_window_for_process') do
      context('raises an error') do
        it('when command is invalid') do
          expect { subject.detect_window_for_process('invalid_command') }
            .to raise_error(Error, /Error executing process: No such file or directory/)
        end

        it('when command ends') do
          expect { subject.detect_window_for_process('/bin/ls > /dev/null', 1) }
            .to raise_error(Error, /Error executing process, is dead/)
        end

        it('when command does not create a window') do
          non_dying_command = 'sleep 5'
          expect { subject.detect_window_for_process(non_dying_command, 1) }
            .to raise_error(Error, /Error executing process, it didn't open a window/)
        end
      end

      it('launches a new gedit window and process') do
        previous_pids = current_user_pids
        window = subject.detect_window_for_process('gedit --new-window /tmp/some_file.txt -s')
        expect(previous_pids).not_to include(window.pid)
      ensure
        WindowManager.new.close(window) if window
      end

      let(:user_id) { `id -u`.strip }
      let(:current_user_pids) { `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i) }
    end
  end
end
