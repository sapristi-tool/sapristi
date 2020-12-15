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

        expect(subject.send(:cmd_for_pid, actual_window.pid)).to eq('sol')
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
  end
end
