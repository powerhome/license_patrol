# frozen_string_literal: true

# These are integration tests, so reaching directly into LicensePatrol is forbidden
# DO NOT:
# require 'rubygems'
# require 'bundler/setup'
# require 'license_patrol'

require_relative 'testing_dsl'

RSpec.configure do |rspec|
  rspec.default_formatter = 'doc'

  rspec.before(:each) do
    LicensePatrol::TestingDSL::Paths.reset_projects!
  end
end
