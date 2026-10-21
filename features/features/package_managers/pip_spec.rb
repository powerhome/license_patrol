# frozen_string_literal: true

require_relative '../../support/feature_helper'
require_relative '../../../lib/license_patrol/platform'

describe 'Pip Dependencies' do
  # As a Python developer
  # I want to be able to manage Pip dependencies

  let(:python_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::PipProject.create
    python_developer.run_license_patrol
    expect(python_developer).to be_seeing_line 'rsa, 3.1.4, "Apache 2.0"'
  end

  context 'when there are platform markers' do
    context 'when platform markers match the current system OS' do
      it 'should show up in the report' do
        platform = if LicensePatrol::Platform.darwin?
                     'Darwin'
                   elsif LicensePatrol::Platform.windows?
                     'Windows'
                   else
                     'Linux' # Internal test uses Linux platform
                   end

        project = LicensePatrol::TestingDSL::PipProject.new
        project.add_dep_with_platform(platform)
        project.add_dep
        project.install
        python_developer.run_license_patrol
        expect(python_developer).to be_seeing_line 'colorama, 0.3.9, BSD'
      end
    end

    context 'when platform markers do not match the current system OS' do
      it 'should not show up in the report' do
        project = LicensePatrol::TestingDSL::PipProject.new
        project.add_dep_with_platform('different-platform')
        project.add_dep
        project.install
        python_developer.run_license_patrol
        expect(python_developer).to_not be_seeing_line 'colorama, 0.3.9, BSD'
      end
    end
  end
end
