# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'SPM Dependencies' do
  # As a developer on Apple platforms
  # I want to be able to manage Swift Package Manager dependencies

  let(:apple_platform_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::SpmProject.create
    apple_platform_developer.run_license_patrol
    expect(apple_platform_developer).to be_seeing_line 'URLSessionDecodable, 0.1.0, "Apache 2.0"'
  end
end
