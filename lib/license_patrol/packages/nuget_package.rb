# frozen_string_literal: true

module LicensePatrol
  class NugetPackage < Package
    def package_manager
      'Nuget'
    end

    def package_url
      "https://www.nuget.org/packages/#{CGI.escape(name)}/#{CGI.escape(version)}"
    end
  end
end
