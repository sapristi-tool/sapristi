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

    context 'wait time' do
      it 'reads wait time' do
        expect(subject.parse(['-w', '10']).wait_time).to eq(10)
        expect(subject.parse(['--wait-time', '10']).wait_time).to eq(10)
      end

      it 'wait_time is an integer' do
        expect { subject.parse(['-w', '10.0']) }.to raise_error(OptionParser::InvalidOption, /-w '10.0' is not an integer/)
      end

      it 'is a positive number' do
        expect { subject.parse(['-w', '0']) }.to raise_error(OptionParser::InvalidOption, /-w requires a wait time > 0, provided=0/)
      end

      it 'is less than 2 minutes' do
        expect { subject.parse(['-w', '121']) }.to raise_error(OptionParser::InvalidOption, /-w requires a wait time <= 120 seconds, provided=121/)
      end
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
