# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'CocoaPods Dependencies', ios: true do
  # As a Cocoa developer
  # I want to be able to manage CocoaPods dependencies

  let(:cocoa_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::CocoaPodsProject.create
    cocoa_developer.run_license_patrol
    expect(cocoa_developer).to be_seeing_line 'ABTest, 0.0.5, MIT'
  end
end
