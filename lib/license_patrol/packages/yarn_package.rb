# frozen_string_literal: true

module LicensePatrol
  class YarnPackage < Package
    def package_manager
      'Yarn'
    end

    def package_url
      "https://yarn.pm/#{CGI.escape(name)}"
    end
  end
end
