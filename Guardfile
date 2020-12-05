# frozen_string_literal: true

group :red_green_refactor, halt_on_fail: true do
  guard :rspec, cmd: 'rspec' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(?:sapristi/)?(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb') { 'spec' }
    watch('bin/sapristi') { 'spec/sapristi_runner_spec.rb' }
  end

  guard :rubocop, all_on_start: false, cli: ['--format', 'html', '-o', './tmp/rubocop.html'] do
    watch(%r{^spec/.+\.rb$})
    watch(%r{^lib/.+\.rb$})
    watch('bin/sapristi')
  end

  guard :rubycritic do
    watch(%r{^spec/.+\.rb$})
    watch(%r{^lib/.+\.rb$})
    watch('bin/sapristi')
  end

  guard :reek, all_on_start: false, run_all: false, cli: ['--format', 'html', '>', './tmp/reek.html'] do
    watch(%r{^spec/.+\.rb$})
    watch(%r{^lib/.+\.rb$})
    watch('bin/sapristi')
  end
end
