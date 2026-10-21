# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'NPM Dependencies' do
  # As a Node developer
  # I want to be able to manage NPM dependencies

  let(:node_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::NpmProject.create
    node_developer.run_license_patrol
    expect(node_developer).to be_seeing_line 'http-server, 0.11.1, MIT'
    expect(node_developer).to be_seeing_line 'entities, 4.4.0, "Simplified BSD"'
  end
end
