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
      @windows.each { |w| WindowManager.new.close w }
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
        actual_window = subject.detect_window_for_process waiter, timeout
        expect(actual_window).not_to be_nil
      end

      it 'window has the same pid as initial process' do
        actual_window = subject.detect_window_for_process waiter, timeout
        expect(actual_window.pid).to eq(waiter.pid)
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
        waiter1 = new_window
        first_window = subject.detect_window_for_process waiter1, timeout
        expect(first_window).not_to be_nil
        @windows.push first_window

        subject2 = NewProcessWindowDetector.new
        waiter2 = new_window
        second_window = subject2.detect_window_for_process waiter2, timeout
        expect(second_window).not_to be_nil
        @windows.push second_window

        expect(first_window.id).not_to eq(second_window.id)
      end
    end
  end
end
