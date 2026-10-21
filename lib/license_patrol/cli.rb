# frozen_string_literal: true

module LicensePatrol
  module CLI
  end
end

require 'license_patrol/cli/patched_thor'
require 'license_patrol/cli/base'
require 'license_patrol/cli/makes_decisions'
require 'license_patrol/cli/inherited_decisions'
require 'license_patrol/cli/permitted_licenses'
require 'license_patrol/cli/restricted_licenses'
require 'license_patrol/cli/dependencies'
require 'license_patrol/cli/licenses'
require 'license_patrol/cli/approvals'
require 'license_patrol/cli/ignored_groups'
require 'license_patrol/cli/ignored_dependencies'
require 'license_patrol/cli/project_name'
require 'license_patrol/cli/main'
