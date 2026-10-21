# frozen_string_literal: true

require_relative '../../support/feature_helper'
describe 'Composite project' do
  # As a non-technical product owner
  # I want to run license finder on a composite project
  # So that I can easily review all licenses used by sub-projects

  let(:developer) { LicensePatrol::TestingDSL::User.new }

  specify 'shows dependencies for all active projects' do
    LicensePatrol::TestingDSL::CompositeProject.create
    developer.execute_command('license_patrol report --recursive')
    expect(developer).to be_seeing('junit, 4.11, "Common Public License Version 1.0"')
  end

  specify 'shows csv report columns in the right order' do
    LicensePatrol::TestingDSL::CompositeProject.create
    developer.execute_command('license_patrol report --recursive --format csv --columns name version install_path licenses')
    expect(developer).to be_seeing('junit,4.11,,Common Public License Version 1.0')
  end

  specify 'shows install path column when scanning recursively' do
    project = LicensePatrol::TestingDSL::BundlerProject.create
    project.install
    developer.execute_command('license_patrol report --recursive --format csv --columns name version install_path licenses')
    expect(developer).to be_seeing_something_like(%r{tomlrb,2.\d+.\d+,.*/gems/tomlrb-2.\d+.\d+,MIT})
  end
end
