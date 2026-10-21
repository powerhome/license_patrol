# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Bower Dependencies' do
  # As a JS developer
  # I want to be able to manage Bower dependencies

  let(:js_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::BowerProject.create
    js_developer.run_license_patrol
    expect(js_developer).to be_seeing_line 'gmaps, 0.2.30, MIT'
  end
end
