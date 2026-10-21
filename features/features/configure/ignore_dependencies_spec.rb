# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Ignored Dependencies' do
  # As a developer
  # I want to ignore certain dependencies
  # To avoid frequently changing reports about dependencies I know will always be approved

  let(:developer) { LicensePatrol::TestingDSL::User.new }

  before do
    developer.create_empty_project
    developer.execute_command 'license_patrol dependencies add ignored_dep Whatever'
  end

  specify 'are excluded from reports' do
    developer.execute_command 'license_patrol ignored_dependencies add ignored_dep'

    developer.run_license_patrol
    expect(developer).to_not be_seeing 'ignored_dep'
    developer.execute_command('license_patrol report')
    expect(developer).to_not be_seeing 'ignored_dep'
  end

  specify 'appear in the CLI' do
    developer.execute_command 'license_patrol ignored_dependencies add ignored_dep'
    expect(developer).to be_seeing 'ignored_dep'

    developer.execute_command 'license_patrol ignored_dependencies list'
    expect(developer).to be_seeing 'ignored_dep'

    developer.execute_command 'license_patrol ignored_dependencies remove ignored_dep'
    developer.execute_command 'license_patrol ignored_dependencies list'
    expect(developer).to_not be_seeing 'ignored_dep'
  end
end
