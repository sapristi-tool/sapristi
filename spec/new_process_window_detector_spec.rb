# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe NewProcessWindowDetector do
    subject { NewProcessWindowDetector.new }

    let(:kill_sleep_time) { 0.3 }

    let(:timeout) { 5 }
    before(:each) do
      @waiters = []
      @windows = []
    end

    after(:each) do
      @windows.compact.each { |window| WindowManager.new.close window }
      @waiters.each do |waiter|
        Process.kill(9, waiter.pid) if waiter.alive?
        sleep kill_sleep_time
      rescue StandardError => e
        puts e
      end
    end

    it 'honors wait_time' do
      wait_time = 2
      start_time = Time.now
      expect { subject.detect_window_for_process("sleep 5", nil, wait_time) }
        .to raise_error(Error, /it didn't open a window/)

      expect(Time.now - start_time).to be_within(0.3).of(wait_time)
    end

    context('New process per window') do
      let(:command) { 'sol' }
      # let(:waiter) do
      #  pid = Process.spawn command
      #  waiter = Process.detach pid
      #  @waiters.push waiter
      #  waiter
      # end

      it 'detects window for new process' do
        actual_window = subject.detect_window_for_process command, nil, timeout
        @windows.push actual_window

        expect(actual_window).not_to be_nil
      end

      it 'ignores windows with _NET_WM_STATE_SKIP_TASKBAR' do
        allow(subject).to receive(:skip_taskbar?).and_return(true)

        expect { subject.detect_window_for_process command, nil, 1 }.to raise_error(Error, /it didn't open a window/)
        sleep 0.2 # close splash window created
      end

      it 'ignores windows with _NET_WM_STATE_SKIP_PAGER' do
        allow(subject).to receive(:skip_pager?).and_return(true)

        expect { subject.detect_window_for_process command, nil, 1 }.to raise_error(Error, /it didn't open a window/)
        sleep 0.2 # close splash window created
      end

      it 'window has the same pid as initial process' do
        actual_window = subject.detect_window_for_process command, nil, timeout
        @windows.push actual_window

        expect(Linux::ProcessManager.cmd_for_pid(actual_window.pid)).to eq(command)
      end
    end

    context('Same process spawns several children/windows') do
      let(:command) { 'gedit --new-window' }
      def launch_external
        pid = Process.spawn command, pgroup: true
        Process.detach pid
        start_date = Time.now

        while Time.now - start_date < timeout
          windows = OSFactory.new.window_manager.windows(title: /gedit/)
          break unless windows.empty?
        end

        raise Error, "Unexpected windows #{windows.size}, expect just one" if windows.size != 1

        window = windows.first
        @windows.push window
        window
      end

      def launch_command
        window = subject.detect_window_for_process command, nil, timeout
        @windows.push window
        window
      end

      before(:all) { expect(OSFactory.new.window_manager.windows(title: /gedit/)).to be_empty }

      it 'detects two windows with same parent process' do
        first_window = launch_command

        expect(first_window).not_to be_nil

        second_window = launch_command

        expect(second_window).not_to be_nil

        expect(first_window.id).not_to eq(second_window.id)
      end

      it 'detects window if parent process was launched outside of sapristi watch' do
        external_parent_process_window = launch_external

        window = launch_command
        expect(window).not_to be_nil
        expect(window.id).not_to eq(external_parent_process_window.id)
        expect(Process.getpgid(window.pid)).to eq(Process.getpgid(external_parent_process_window.pid))
      end
    end

    context 'process does not execute in background' do
      let(:command) { 'gnome-terminal --disable-factory' }

      # before(:all) { expect(OSFactory.new.window_manager.windows(title: /zeal/)).to be_empty }

      it 'can launch the process' do
        actual_window = subject.detect_window_for_process command, nil, timeout
        @windows.push actual_window

        expect(actual_window).not_to be_nil
      end

      it 'can launch the process twice' do
        actual_window = subject.detect_window_for_process command, nil, timeout
        @windows.push actual_window

        expect(actual_window).not_to be_nil

        another_window = subject.detect_window_for_process command, nil, timeout
        @windows.push another_window

        expect(another_window).not_to be_nil
        expect(another_window.id).not_to eq(actual_window.id)
      end
    end

    context 'program talks with server to create a child window not a new process' do
      let(:command) { 'subl -n /tmp' }

      before(:all) { expect(OSFactory.new.window_manager.windows(title: /Sublime/)).not_to be_empty }

      it 'can launch the process' do
        actual_window = subject.detect_window_for_process command, nil, timeout
        @windows.push actual_window

        expect(actual_window).not_to be_nil
      end
    end

    context('#detect_window_for_process') do
      context('raises an error') do
        it('when command is invalid') do
          expect { subject.detect_window_for_process('invalid_command', nil) }
            .to raise_error(Error, /Error executing process: No such file or directory/)
        end

        it('when command ends') do
          expect { subject.detect_window_for_process('/bin/ls > /dev/null', nil, 1) }
            .to raise_error(Error, /Error executing process, is dead/)
        end

        it('when command does not create a window') do
          non_dying_command = 'sleep 5'
          expect { subject.detect_window_for_process(non_dying_command, nil, 1) }
            .to raise_error(Error, /Error executing process, it didn't open a window/)
        end
      end

      it('launches a new gedit window and process') do
        previous_pids = current_user_pids
        window = subject.detect_window_for_process('gedit --new-window /tmp/some_file.txt -s', nil)
        expect(previous_pids).not_to include(window.pid)
      ensure
        WindowManager.new.close(window) if window
      end

      let(:user_id) { `id -u`.strip }
      let(:current_user_pids) { `ps -u #{user_id}`.split("\n")[1..nil].map(&:to_i) }
    end
  end
end
