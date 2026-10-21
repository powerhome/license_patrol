# frozen_string_literal: true

require 'spec_helper'

module LicensePatrol
  describe NugetPackage do
    subject { described_class.new 'nuget_package' }

    its(:package_manager) { should == 'Nuget' }
  end
end
