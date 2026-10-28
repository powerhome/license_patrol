# frozen_string_literal: true

module LicensePatrol
  class Yarn < PackageManager
    def initialize(options = {})
      super
      @yarn_options = options[:yarn_options]
    end

    SHELL_COMMAND = 'yarn licenses list --recursive --json'
    BERRY_SHELL_COMMAND = 'yarn info --all --recursive --json --extra manifest'

    def possible_package_paths
      [project_path.join('yarn.lock')]
    end

    def current_packages
      if yarn_version == 1
        get_yarn1_packages(run_json_command(classic_shell_command))
      else
        get_yarn_packages(run_json_command(BERRY_SHELL_COMMAND))
      end
    end

    def prepare
      prep_cmd = prepare_command.to_s
      _stdout, stderr, status = Dir.chdir(project_path) { Cmd.run(prep_cmd) }
      return if status.success?

      log_errors stderr
      raise "Prepare command '#{prep_cmd}' failed" unless @prepare_no_fail
    end

    def self.takes_priority_over
      NPM
    end

    def package_management_command
      'yarn'
    end

    def prepare_command
      if yarn_version == 1
        classic_yarn_prepare_command
      else
        yarn_prepare_command
      end
    end

    private

    # devDependencies are left out when reading the packages, so all of them are installed
    def yarn_prepare_command
      'yarn install'
    end

    def classic_yarn_prepare_command
      "yarn install --ignore-engines --ignore-scripts#{classic_yarn_production_flag}"
    end

    def classic_shell_command
      cmd = "#{Yarn::SHELL_COMMAND}#{classic_yarn_production_flag} --no-progress"
      cmd += " --cwd #{project_path}" unless project_path.nil?
      cmd += " #{@yarn_options}" unless @yarn_options.nil?
      cmd
    end

    def run_json_command(cmd)
      stdout, stderr, status = Dir.chdir(project_path) { Cmd.run(cmd) }
      raise "Command '#{cmd}' failed to execute: #{stderr}" unless status.success?

      json_strings = stdout.encode('ASCII', invalid: :replace, undef: :replace, replace: '?').split("\n")
      json_strings.map { |json_object| JSON.parse(json_object) }
    end

    def yarn_version
      Dir.chdir(project_path) do
        version_string, stderr_str, status = Dir.chdir(project_path) { Cmd.run('yarn -v') }
        raise "Command 'yarn -v' failed to execute: #{stderr_str}" unless status.success?

        version = version_string.split('.').map(&:to_i)
        return version[0]
      end
    end

    # Yarn 2+ prints one line per package in the lockfile, keyed by its locator
    # (e.g. "@babel/core@npm:7.18.6"). Workspaces are the project's own code,
    # so only the packages they depend on are reported.
    def get_yarn_packages(json_objects)
      infos = json_objects.map { |json_object| [json_object['value'], json_object['children']] }.to_h
      locators = ignore_dev_dependencies? ? production_locators(infos) : infos.keys

      packages = locators.reject { |locator| workspace_locator?(locator) }.map do |locator|
        name = locator_name(locator)
        info = infos[locator]
        manifest = info['Manifest'] || {}
        YarnPackage.new(
          name,
          info['Version'],
          spec_licenses: [manifest['License']].compact,
          homepage: manifest['Homepage'],
          install_path: project_path.join(modules_folder, name)
        )
      end

      # a patched package (e.g. typescript) is listed next to the package it patches
      packages.uniq { |package| [package.name, package.version] }
    end

    # Walks the dependencies of every workspace, skipping the ones they declare
    # in devDependencies, like "yarn workspaces focus --all --production".
    def production_locators(infos)
      seen = Set.new
      pending = infos.keys.select { |locator| workspace_locator?(locator) }
      until pending.empty?
        locator = devirtualize(pending.shift)
        next unless infos.key?(locator) && seen.add?(locator)

        dev_dependencies = workspace_locator?(locator) ? workspace_dev_dependencies(locator) : []
        (infos[locator]['Dependencies'] || []).each do |dependency|
          pending << dependency['locator'] unless dev_dependencies.include?(locator_name(dependency['descriptor']))
        end
      end
      seen.to_a
    end

    def workspace_dev_dependencies(locator)
      workspace_path = locator.delete_prefix("#{locator_name(locator)}@workspace:")
      manifest = JSON.parse(File.read(project_path.join(workspace_path, 'package.json')))
      (manifest['devDependencies'] || {}).keys - (manifest['dependencies'] || {}).keys
    end

    def locator_name(locator)
      locator[%r{\A(@[^/@]+/)?[^@]+}]
    end

    def workspace_locator?(locator)
      locator.start_with?("#{locator_name(locator)}@workspace:")
    end

    # "react-dom@virtual:c6e8...#npm:18.2.0" is "react-dom@npm:18.2.0" with its peer dependencies resolved
    def devirtualize(locator)
      locator.sub(/@virtual:[^#]*#/, '@')
    end

    def get_yarn1_packages(json_objects)
      packages = []
      if json_objects.last['type'] == 'table'
        license_json = json_objects.pop['data']
        packages = packages_from_json(license_json)
      end

      incompatible_packages = []
      json_objects.each do |json_object|
        match = %r{(?<name>@?[\w/.-]+)@(?<version>(\d+\.?)+)} =~ json_object['data'].to_s
        if match
          package = YarnPackage.new(name, version, spec_licenses: ['unknown'])
          incompatible_packages.push(package)
        end
      end

      packages + incompatible_packages.uniq
    end

    def packages_from_json(json_data)
      body = json_data['body']
      head = json_data['head']

      packages = body.map do |json_package|
        Hash[head.zip(json_package)]
      end

      valid_packages = filter_yarn_internal_package(packages)

      valid_packages.map do |package_hash|
        YarnPackage.new(
          package_hash['Name'],
          package_hash['Version'],
          spec_licenses: [package_hash['License']],
          homepage: package_hash['VendorUrl'],
          authors: package_hash['VendorName'],
          install_path: project_path.join(modules_folder, package_hash['Name'])
        )
      end
    end

    def modules_folder
      return @modules_folder if @modules_folder

      stdout, _stderr, status = Dir.chdir(project_path) { Cmd.run('yarn config get modules-folder') }
      @modules_folder = 'node_modules' if !status.success? || stdout.strip == 'undefined'
      @modules_folder ||= stdout.strip
    end

    # remove fake package created by yarn [Yarn Bug]
    def filter_yarn_internal_package(all_packages)
      internal_package_pattern = /workspace-aggregator-[a-zA-z0-9]{8}-[a-zA-z0-9]{4}-[a-zA-z0-9]{4}-[a-zA-z0-9]{4}-[a-zA-z0-9]{12}/
      yarn_internal_package = all_packages.find { |package| internal_package_pattern.match(package['Name']) }
      all_packages - [yarn_internal_package]
    end

    def classic_yarn_production_flag
      ignore_dev_dependencies? ? ' --production' : ''
    end

    def ignore_dev_dependencies?
      !@ignored_groups.nil? && @ignored_groups.include?('devDependencies')
    end
  end
end
