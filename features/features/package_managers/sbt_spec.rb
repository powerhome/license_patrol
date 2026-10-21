# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'SBT Dependencies' do
  # As a Scala developer
  # I want to be able to manage SBT dependencies

  let(:scala_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::SbtProject.create
    scala_developer.run_license_patrol 'sbt'
    expect(scala_developer).to be_seeing_line 'scalatest_2.12, 3.0.3, "the Apache License, ASL Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)"'
  end

  context 'when using --sbt_include_groups flag' do
    it 'shows the groupid' do
      LicensePatrol::TestingDSL::SbtProject.create
      scala_developer.run_license_patrol 'sbt', '--sbt_include_groups'
      expect(scala_developer).to be_seeing_line 'org.scalatest:scalatest_2.12, 3.0.3, "the Apache License, ASL Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)"'
    end
  end
end
