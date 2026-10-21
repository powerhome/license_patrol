# frozen_string_literal: true

module LicensePatrol
  class License
    class NoneMatcher
      def matches_text?(_text)
        false
      end
    end
  end
end
