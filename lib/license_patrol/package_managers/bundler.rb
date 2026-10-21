# frozen_string_literal: true

require 'bundler'
require 'securerandom'

module LicensePatrol
  class Bundler < PackageManager
    def initialize(options = {})
      super
      @ignored_groups = options[:ignored_groups]
      @definition = options[:definition] # dependency injection for tests
    end

    def current_packages
      with_gemfile do
        logger.debug self.class, "including groups #{included_groups.inspect}"
        details.map do |gem_detail, bundle_detail|
          BundlerPackage.new(gem_detail, bundle_detail, logger: logger).tap do |package|
            log_package_dependencies package
          end
        end
      end
    end

    def package_management_command
      'bundle'
    end

    def prepare_command
      ignored_groups_argument = !ignored_groups.empty? ? "--without #{ignored_groups.to_a.join(' ')}" : ''

      gem_path = "lf-bundler-gems-#{SecureRandom.uuid}"
      logger.info self.class, "Running bundle install for #{Dir.pwd} with path #{gem_path}", color: :blue

      "bundle install #{ignored_groups_argument} --path #{gem_path}".strip
    end

    def possible_package_paths
      [gemfile_path]
    end

    private

    attr_reader :ignored_groups

    def definition
      return @definition if @definition

      @definition = ::Bundler::Definition.build(detected_package_path, lockfile_path, nil) if detected_package_path
    end

    def with_gemfile
      previous_gemfile = ENV['BUNDLE_GEMFILE']
      ENV['BUNDLE_GEMFILE'] = gemfile_path.to_s
      yield
    ensure
      ENV['BUNDLE_GEMFILE'] = previous_gemfile
    end

    def details
      gem_details.map do |gem_detail|
        bundle_detail = bundler_details.detect { |bundler_detail| bundler_detail.name == gem_detail.name }
        [gem_detail, bundle_detail]
      end
    end

    def gem_details
      return @gem_details if @gem_details

      # clear gem paths before running specs_for
      Gem.clear_paths
      if bundler_config_path_found
        ::Bundler.reset!
        ::Bundler.configure
      end
      @gem_details = definition&.specs_for(included_groups) || []
    end

    def bundler_details
      @bundler_details ||= definition&.dependencies || []
    end

    def included_groups
      definition_groups - ignored_groups.map(&:to_sym)
    end

    def definition_groups
      definition&.groups || []
    end

    def lockfile_path
      Pathname("#{gemfile_path}.lock")
    end

    # Bundler keeps the config (e.g. BUNDLE_PATH for vendored gems) next to the gemfile
    def bundler_config_path_found
      config_file = gemfile_path.dirname.join('.bundle/config')

      return false unless File.exist?(config_file)

      content = File.readlines(config_file)
      content.grep(/BUNDLE_PATH/).count.positive?
    end

    def log_package_dependencies(package)
      dependencies = package.children
      if dependencies.empty?
        logger.debug self.class, format("package '%s' has no dependencies", package.name)
      else
        logger.debug self.class, format("package '%s' has dependencies:", package.name)
        dependencies.each do |dep|
          logger.debug self.class, format('- %s', dep)
        end
      end
    end

    def gemfile_path
      @gemfile_path ||= project_path.join(gemfile)
    end

    # BUNDLE_GEMFILE is taken as relative to the project path. Through `bundle exec`
    # it gets expanded to an absolute path, which may point to another project
    # (e.g. when using --project_path), in which case only its basename is kept.
    def gemfile
      gemfile = ENV['BUNDLE_GEMFILE']
      return 'Gemfile' if gemfile.nil? || gemfile.empty?
      return gemfile unless Pathname(gemfile).absolute?

      gemfile = Pathname(gemfile).expand_path
      project_root = project_path.expand_path
      gemfile.ascend.any? { |path| path == project_root } ? gemfile.to_s : gemfile.basename.to_s
    end
  end
end
