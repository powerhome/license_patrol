# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Carthage Dependencies', ios: true do
  # As a developer on Apple platforms
  # I want to be able to manage Carthage dependencies

  let(:apple_platform_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::CarthageProject.create
    apple_platform_developer.run_license_patrol
    expect(apple_platform_developer).to be_seeing_line 'DSWaveformImage, 1.1.2, MIT'
  end
end
