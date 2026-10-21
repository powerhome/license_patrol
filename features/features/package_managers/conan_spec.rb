# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Conan Dependencies' do
  let(:conan_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports for a project' do
    LicensePatrol::TestingDSL::ConanProject.create
    conan_developer.run_license_patrol
    expect(conan_developer).to be_seeing_line 'range-v3, 0.10.0, MIT'
  end
end
