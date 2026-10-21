# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Restricted licenses' do
  # As a lawyer
  # I want to restrict certain licenses
  # So that any dependencies with only these licenses cannot be approved

  let(:developer) { LicensePatrol::TestingDSL::User.new }
  let(:lawyer) { LicensePatrol::TestingDSL::User.new }

  before do
    developer.create_empty_project
    lawyer.execute_command 'license_patrol restricted_licenses add BSD'
    developer.execute_command 'license_patrol dependencies add restricted_dep BSD 1.2'
  end

  specify 'prevent packages from being approved' do
    developer.execute_command 'license_patrol approval add restricted_dep'

    lawyer.run_license_patrol
    expect(lawyer).to be_seeing 'restricted_dep'
  end

  specify 'override the permitted licenses' do
    developer.execute_command 'license_patrol permitted_licenses add BSD'

    lawyer.run_license_patrol
    expect(lawyer).to be_seeing 'restricted_dep'
  end
end
