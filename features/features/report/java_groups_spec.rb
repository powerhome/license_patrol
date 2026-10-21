# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Composite project' do
  let(:developer) { LicensePatrol::TestingDSL::User.new }

  specify 'shows dependencies for all active projects' do
    LicensePatrol::TestingDSL::BareGradleProject.create
    developer.execute_command('license_patrol report --gradle_include_groups')
    expect(developer).to be_seeing('junit:junit, 4.11, "Common Public License Version 1.0"')
  end
end
