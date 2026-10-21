# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'license_patrol'

require 'rspec'
require 'webmock/rspec'
require 'rspec/its'
require 'tmpdir'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].sort.each do |file|
  require file
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run_when_matching :focus

  config.include SharedDefinitions

  # Specs write to the default ./doc decisions file, so set the project's own aside
  doc_dir = Pathname('./doc')
  doc_backup = Pathname(Dir.mktmpdir).join('doc')

  config.before(:suite) do
    FileUtils.mv(doc_dir, doc_backup) if doc_dir.directory?
  end

  config.after(:suite) do
    doc_dir.rmtree if doc_dir.directory?
    FileUtils.mv(doc_backup, doc_dir) if doc_backup.directory?
  end

  config.include LicensePatrol::TestFixtures
end
