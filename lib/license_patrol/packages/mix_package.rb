# frozen_string_literal: true

module LicensePatrol
  class MixPackage < Package
    def package_manager
      'Mix'
    end

    def package_url
      "https://hex.pm/packages/#{CGI.escape(name)}/#{CGI.escape(version)}"
    end
  end
end
