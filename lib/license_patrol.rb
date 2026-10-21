# frozen_string_literal: true

require 'pathname'
require 'yaml'

module LicensePatrol
  ROOT_PATH = Pathname.new(__FILE__).dirname.join('license_patrol')
  BIN_PATH = ROOT_PATH.join('../../bin')
end

require 'license_patrol/shared_helpers/cmd'

require 'license_patrol/core'
require 'license_patrol/cli'
