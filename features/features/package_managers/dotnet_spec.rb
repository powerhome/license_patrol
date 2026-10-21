# frozen_string_literal: true

require_relative '../../support/feature_helper'

describe 'Dotnet dependencies' do
  let(:dotnet_developer) { LicensePatrol::TestingDSL::User.new }

  specify 'are shown in reports' do
    LicensePatrol::TestingDSL::DotnetProject.create
    dotnet_developer.run_license_patrol 'dotnet'
    expect(dotnet_developer).to be_seeing_line 'Microsoft.AspNet.WebApi.Client, 5.2.6, http://www.microsoft.com/web/webpi/eula/net_library_eula_ENU.htm'
  end
end
