# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'PNPM Dependencies' do
  # As a Node developer
  # I want to be able to manage PNPM dependencies

  let(:node_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::PNPMProject.create
    node_developer.run_license_patrol
    expect(node_developer).to be_seeing_line 'http-server, 0.11.1, MIT'
  end
end
