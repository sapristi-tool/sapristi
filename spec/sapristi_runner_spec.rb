# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

load File.join File.expand_path(File.dirname(__FILE__)), '..', '/bin/sapristi'

module Sapristi
  RSpec.describe 'SapristiRunner' do
    let(:runner_path) { File.join 'bin', 'sapristi'}
    
    it 'is executable' do
      expect(File.executable? runner_path).to be_truthy
    end

    it 'calls sapristin run with no args' do
      expect_any_instance_of(Sapristi).to receive(:run).with(no_args)

      run_sapristi []
    end

    it 'calls sapristi run with verbose' do
      expect_any_instance_of(Sapristi).to receive(:verbose!)
      allow_any_instance_of(Sapristi).to receive(:run)
      
      run_sapristi ["-v"]
    end

    it 'calls sapristi run with file' do
      expected_file = "/tmp/foo"
      allow_any_instance_of(Sapristi).to receive(:run).with(expected_file)
      
      run_sapristi ["-f", expected_file]
    end

    it 'calls sapristi run dry' do
      expect_any_instance_of(Sapristi).to receive(:dry!)
      allow_any_instance_of(Sapristi).to receive(:run)
      
      run_sapristi ["--dry-run"]
    end
  end
end