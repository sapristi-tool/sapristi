# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

load File.join __dir__, '..', '/bin/sapristi'

module Sapristi
  RSpec.describe 'SapristiRunner' do
    let(:runner_path) { File.join 'bin', 'sapristi' }

    it 'is executable' do
      expect(File.executable?(runner_path)).to be_truthy
    end

    it 'calls sapristin run with no args' do
      expect_any_instance_of(Sapristi).to receive(:run).with(no_args)

      run_sapristi []
    end

    it 'calls sapristi run with verbose' do
      expect_any_instance_of(Sapristi).to receive(:verbose!)
      allow_any_instance_of(Sapristi).to receive(:run)

      run_sapristi ['-v']
    end

    it 'calls sapristi run with file' do
      expected_file = '/tmp/foo'
      allow_any_instance_of(Sapristi).to receive(:run).with(expected_file)

      run_sapristi ['-f', expected_file]
    end

    it 'calls sapristi run dry' do
      expect_any_instance_of(Sapristi).to receive(:dry!)
      allow_any_instance_of(Sapristi).to receive(:run)

      run_sapristi ['--dry-run']
    end

    context 'errors' do
      let(:valid_headers) { %w[Title Command Monitor X-position Y-position H-size V-size Workspace] }
      let(:separator) { ',' }

      context('sapristi errors') do
        it 'output sapristi errors in stderr' do
          invalid_file = '/tmp/non_existing_file'
          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)

          expect { run_sapristi ['-f', invalid_file] }.to output(/#{invalid_file}/).to_stderr
        end

        it 'output line number if available' do
          file = Tempfile.create('foo')
          file.write
          file.write(valid_headers.join(separator))
          file.write "\n"
          file.write(valid_headers.map { |_a| '' }.join(separator))
          file.close

          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)
          expect { run_sapristi ['-f', file.path] }.to output(/.+, line=0/).to_stderr
        end

        it 'return 1 status' do
          invalid_file = '/tmp/non_existing_file'

          expect { run_sapristi ['-f', invalid_file] }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end
      end

      context('unexpected errors') do
        it 'says there is been an error' do
          expect_any_instance_of(Sapristi).to receive(:run).and_raise(ArgumentError, 'some')

          allow_any_instance_of(Kernel).to receive(:exit).and_return(1)
          expect { run_sapristi [] }.to output(%r{Sapristi crashed, see /tmp/sapristi.stacktrace.[0-9]+.log}).to_stderr
        end

        it 'generates a crash file in tmp with the stack trace' do
          expect_any_instance_of(Sapristi).to receive(:run).and_raise(ArgumentError, 'some')

          allow($stderr).to receive(:puts)
          expect { run_sapristi [] }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(2)

            expect($stderr).to have_received(:puts).with(lambda { |args|
              error_file = args.match(%r{(/tmp.+)$})[1]
              stacktrace = File.readlines(error_file).map(&:chomp)

              expect(stacktrace[0]).to eq("#{ArgumentError}: some")
              expect(stacktrace[1..-1].size).to be > 2
            })
          end
        end

        it 'return 2 status' do
          expect_any_instance_of(Sapristi).to receive(:run).and_raise(ArgumentError, 'some')

          expect { run_sapristi [] }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(2)
          end
        end
      end
    end
  end
end
