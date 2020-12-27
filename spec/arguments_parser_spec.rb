# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

module Sapristi
  RSpec.describe ArgumentsParser do
    subject { ArgumentsParser.new }

    it 'can specify a group' do
      group = 'group'
      expect(subject.parse(['-g', group]).group).to eq(group)
      expect(subject.parse(['--group', group]).group).to eq(group)
    end

    it 'show monitors' do
      expect(subject.parse(['-m']).show_monitors).to be_truthy
      expect(subject.parse(['--monitors']).show_monitors).to be_truthy
    end

    it 'default group is nil' do
      expect(subject.parse([]).group).to be_nil
    end

    it 'can enable verbose mode' do
      expect(subject.parse(['-v']).verbose).to be_truthy
      expect(subject.parse(['--verbose']).verbose).to be_truthy
    end

    it 'verbose mode disabled by default' do
      expect(subject.parse([]).verbose).to be_falsey
    end

    it 'reads configuration file from option' do
      expected_file = '/tmp/foo'
      expect(subject.parse(['-f', expected_file]).file).to eq(expected_file)
      expect(subject.parse(['--file', expected_file]).file).to eq(expected_file)
    end

    it 'reads dry run' do
      expect(subject.parse(['--dry-run']).dry).to be_truthy
    end
  end
end
