# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

load File.join __dir__, '..', '/bin/sapristi'

module Sapristi
  RSpec.describe Runner do
    let(:runner_path) { File.join 'bin', 'sapristi' }
    subject { Runner.new }
    # before(:each) { allow(subject).to receive(:exit_error) }

    it 'is executable' do
      expect(File.executable?(runner_path)).to be_truthy
    end

    it 'calls sapristin run with no args' do
      expect_any_instance_of(Sapristi).to receive(:run).with(no_args)

      subject.run []
    end

    it 'shows monitor\'s info' do
      allow_any_instance_of(Sapristi).to receive(:run).with(no_args)
      expect { subject.run ['-m'] }.to output(/Monitors: [0-9]+.*/).to_stdout
    end

    it 'calls sapristi run with verbose' do
      expect_any_instance_of(Sapristi).to receive(:verbose!)
      allow_any_instance_of(Sapristi).to receive(:run)

      subject.run ['-v']
    end

    it 'calls sapristi run with file' do
      expected_file = '/tmp/foo'
      allow_any_instance_of(Sapristi).to receive(:run).with(expected_file)

      subject.run ['-f', expected_file]
    end

    it 'calls sapristi run dry' do
      expect_any_instance_of(Sapristi).to receive(:dry!)
      allow_any_instance_of(Sapristi).to receive(:run)

      subject.run ['--dry-run']
    end

    it 'calls sapristi with a group' do
      group = 'some'
      expect_any_instance_of(Sapristi).to receive(:filter!).with(group)
      allow_any_instance_of(Sapristi).to receive(:run)

      subject.run ['--group', group]
    end

    context 'errors' do
      let(:valid_headers) { %w[Title Command Monitor X-position Y-position H-size V-size Workspace] }
      let(:separator) { ',' }

      context('sapristi errors') do
        it 'output sapristi errors in stderr' do
          invalid_file = '/tmp/non_existing_file'
          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)

          expect { subject.run ['-f', invalid_file] }.to output(/#{invalid_file}/).to_stderr
        end

        def create_valid_file_one_line(values)
          definition = build :valid_hash, attrs: values
          build(:valid_csv_file_path, rows: [definition])
        end

        it 'output line number if available' do
          file = create_valid_file_one_line('Command' => nil, 'Title' => nil)

          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)
          expect { subject.run ['-f', file] }.to output(/.+, line=0/).to_stderr
        end

        it 'return 1 status' do
          invalid_file = '/tmp/non_existing_file'

          expect { subject.run ['-f', invalid_file] }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end
      end

      context('unexpected errors') do
        let(:expected_error) { ArgumentError.new('some') }
        before(:each) do
          expect_any_instance_of(Sapristi).to receive(:run).and_raise(expected_error)
          allow($stderr).to receive(:puts)
        end

        it 'says there is been an error' do
          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)
          expect { subject.run [] }.to output(%r{Sapristi crashed, see /tmp/sapristi.stacktrace.[0-9]+.log}).to_stderr
        end

        it 'generates a crash file in tmp with the stack trace' do
          allow(subject).to receive(:exit_error)
          allow(subject).to receive(:save_stacktrace)

          subject.run []

          expect(subject).to have_received(:save_stacktrace).with(expected_error)
        end

        it 'return 2 status' do
          allow(subject).to receive(:exit_error)
          subject.run []

          expect(subject).to have_received(:exit_error).with(2, any_args)
        end

        it 'exit_error raises SystemExit with code and error message' do
          expect { subject.run [] }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(2)
            error_regex = %r{Sapristi crashed, see /tmp/.+}

            validate_error_mesage error_regex
          end
        end

        def validate_error_mesage(error_regex)
          expect($stderr).to have_received(:puts)
            .with(->(error_line) { expect(error_line).to match(error_regex) })
        end
      end
    end
  end
end

module Helper
  def self.read_stacktrace(error_file)
    File.readlines(error_file).map(&:chomp)
  end
end
