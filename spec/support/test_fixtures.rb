# frozen_string_literal: true

module LicensePatrol
  module TestFixtures
    def fixture_path(fixture)
      LicensePatrol::ROOT_PATH.join('..', '..', 'spec', 'fixtures', fixture)
    end

    def fixture_from(filename)
      filepath = LicensePatrol::ROOT_PATH.join('..', '..', 'spec', 'fixtures', 'config', filename)
      File.open(filepath, &:read)
    end
  end
end
