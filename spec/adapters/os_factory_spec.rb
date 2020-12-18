# frozen_string_literal: true

require 'spec_helper'

module Sapristi
  RSpec.describe OSFactory do
    subject { OSFactory.new }
    it 'returns linux module when linux detected' do
      expect(subject.factory_module).to eq(Linux)
    end

    it 'raises an error when OS is not known/implemented' do
      allow(subject).to receive(:linux?).and_return(false)

      expect { subject.factory_module }.to raise_error(Error, /OS not implemented/)
    end

    it 'gets window manager for linux' do
      expect(subject.window_manager).to be_instance_of(Linux::WindowManager)
    end

    it 'gets process manager for linux' do
      expect(subject.process_manager).to eq(Linux::ProcessManager)
    end

    it 'gets monitor manager for linux' do
      expect(subject.monitor_manager).to be_instance_of(Linux::MonitorManager)
    end
  end
end
