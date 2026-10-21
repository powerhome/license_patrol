# frozen_string_literal: true

module LicensePatrol
  class Report
    def self.of(dependencies, options)
      new(dependencies, options).to_s
    end

    def initialize(dependencies, options)
      @dependencies = dependencies
      @project_name = options[:project_name]
      @use_spdx_id = options[:use_spdx_id]
    end

    private

    attr_reader :dependencies, :project_name, :use_spdx_id

    def sorted_dependencies
      dependencies.sort
    end
  end
end

require 'license_patrol/reports/erb_report'
require 'license_patrol/reports/csv_report'
require 'license_patrol/reports/text_report'
require 'license_patrol/reports/diff_report'
require 'license_patrol/reports/merged_report'
require 'license_patrol/reports/html_report'
require 'license_patrol/reports/markdown_report'
require 'license_patrol/reports/xml_report'
require 'license_patrol/reports/json_report'
require 'license_patrol/reports/junit_report'
