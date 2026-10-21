#!/usr/bin/env ruby

# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

# This is an example of how to programatically generate a report using a custom
# ERB template. Run with
# > bundle install
# > ./custom_erb_template.rb

require 'license_patrol'

# See lib/license_patrol/core.rb for more configuration options.
# A quiet logger is required when running reports...
lf = LicensePatrol::Core.new(LicensePatrol::Configuration.with_optional_saved_config(logger: :quiet))

# Find many more examples of complex ERB templates in
# lib/license_patrol/reports/templates/
template = Pathname.new('./sample_template.erb')
print LicensePatrol::ErbReport
  .new(lf.acknowledged, project_name: lf.project_name)
  .to_s(template)
