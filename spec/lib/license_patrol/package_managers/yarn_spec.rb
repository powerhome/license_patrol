# frozen_string_literal: true

require 'spec_helper'
require 'fakefs/spec_helpers'
require 'json'

module LicensePatrol
  describe Yarn do
    let(:root) { '/fake-node-project' }
    it_behaves_like 'a PackageManager'

    let(:yarn1_shell_command_output) do
      {
        'type' => 'table',
        'data' => {
          'body' => [
            ['@sindresorhus/is', '0.7.0', 'MIT', 'https://github.com/sindresorhus/is.git', 'sindresorhus.com', 'Sindre Sorhus'],
            ['yn', '2.0.0', 'MIT', 'https://github.com/sindresorhus/yn.git', 'sindresorhus.com', 'Sindre Sorhus']
          ],
          'head' => %w[Name Version License URL VendorUrl VendorName]
        }
      }.to_json
    end

    let(:yarn_shell_command_output) do
      [
        { 'value' => 'root-app@workspace:.',
          'children' => { 'Version' => '0.0.0', 'Manifest' => { 'License' => 'MIT', 'Homepage' => nil },
                          'Dependencies' => [
                            { 'descriptor' => '@acme/sub@workspace:*', 'locator' => '@acme/sub@workspace:packages/sub' },
                            { 'descriptor' => 'left-pad@npm:1.3.0', 'locator' => 'left-pad@npm:1.3.0' },
                            { 'descriptor' => 'react-dom@virtual:c6e817ae#npm:18.2.0', 'locator' => 'react-dom@virtual:c6e817ae#npm:18.2.0' },
                            { 'descriptor' => 'typescript@patch:typescript@npm%3A5.4.5#optional!builtin<compat/typescript>',
                              'locator' => 'typescript@patch:typescript@npm%3A5.4.5#optional!builtin<compat/typescript>::version=5.4.5&hash=5adc0c' }
                          ] } },
        { 'value' => '@acme/sub@workspace:packages/sub',
          'children' => { 'Version' => '1.0.0', 'Manifest' => { 'License' => nil, 'Homepage' => nil },
                          'Dependencies' => [
                            { 'descriptor' => '@types/jest@npm:^26.0.23', 'locator' => '@types/jest@npm:26.0.24' },
                            { 'descriptor' => 'is-number@npm:7.0.0', 'locator' => 'is-number@npm:7.0.0' }
                          ] } },
        { 'value' => '@types/jest@npm:26.0.24',
          'children' => { 'Version' => '26.0.24', 'Manifest' => { 'License' => 'MIT', 'Homepage' => 'https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/jest' } } },
        { 'value' => 'is-number@npm:7.0.0',
          'children' => { 'Version' => '7.0.0', 'Manifest' => { 'License' => 'MIT', 'Homepage' => 'https://github.com/jonschlinkert/is-number' } } },
        { 'value' => 'left-pad@npm:1.3.0',
          'children' => { 'Version' => '1.3.0', 'Manifest' => { 'License' => 'WTFPL', 'Homepage' => nil } } },
        { 'value' => 'react-dom@npm:18.2.0',
          'children' => { 'Instances' => 1, 'Version' => '18.2.0', 'Manifest' => { 'License' => 'MIT', 'Homepage' => 'https://reactjs.org/' },
                          'Dependencies' => [{ 'descriptor' => 'scheduler@npm:^0.23.0', 'locator' => 'scheduler@npm:0.23.2' }] } },
        { 'value' => 'scheduler@npm:0.23.2',
          'children' => { 'Version' => '0.23.2', 'Manifest' => { 'License' => nil, 'Homepage' => nil } } },
        { 'value' => 'typescript@npm:5.4.5',
          'children' => { 'Version' => '5.4.5', 'Manifest' => { 'License' => 'Apache-2.0', 'Homepage' => 'https://www.typescriptlang.org/' } } },
        { 'value' => 'typescript@patch:typescript@npm%3A5.4.5#optional!builtin<compat/typescript>::version=5.4.5&hash=5adc0c',
          'children' => { 'Version' => '5.4.5', 'Manifest' => { 'License' => 'Apache-2.0', 'Homepage' => 'https://www.typescriptlang.org/' } } }
      ].map(&:to_json).join("\n")
    end

    describe '.prepare' do
      subject { Yarn.new(project_path: Pathname(root), logger: double(:logger, active: nil)) }

      include FakeFS::SpecHelpers
      before do
        FileUtils.mkdir_p(Dir.tmpdir)
        FileUtils.mkdir_p(root)
      end

      context 'when using Yarn 1.x projects' do
        before do
          allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return(['1.9.4', '', cmd_success])
        end

        it 'should call yarn install with expected cli parameters' do
          expect(SharedHelpers::Cmd).to receive(:run).with('yarn install --ignore-engines --ignore-scripts')
                                                     .and_return([yarn1_shell_command_output, '', cmd_success])
          subject.prepare
        end

        context 'ignored_groups contains devDependencies' do
          subject { Yarn.new(project_path: Pathname(root), ignored_groups: 'devDependencies') }
          it 'should include a production flag' do
            expect(SharedHelpers::Cmd).to receive(:run).with('yarn install --ignore-engines --ignore-scripts --production')
                                                       .and_return([yarn1_shell_command_output, '', cmd_success])
            subject.prepare
          end
        end
      end

      %w[2.0.1 3.0.1 4.9.1].each do |version|
        context "when using Yarn #{version} projects" do
          before do
            allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return([version, '', cmd_success])
          end

          it 'should call yarn install with no cli parameters' do
            expect(SharedHelpers::Cmd).to receive(:run).with('yarn install')
                                                       .and_return(['', '', cmd_success])
            subject.prepare
          end

          context 'ignored_groups contains devDependencies' do
            subject { Yarn.new(project_path: Pathname(root), ignored_groups: 'devDependencies') }

            it 'still installs every dependency' do
              expect(SharedHelpers::Cmd).to receive(:run).with('yarn install')
                                                         .and_return(['', '', cmd_success])
              subject.prepare
            end
          end
        end
      end
    end

    describe '#current_packages' do
      subject { Yarn.new(project_path: Pathname(root), logger: double(:logger, active: nil)) }

      include FakeFS::SpecHelpers
      before do
        FileUtils.mkdir_p(Dir.tmpdir)
        FileUtils.mkdir_p(root)
        allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return(['1.0.1', '', cmd_success])
      end

      %w[2.0.1 3.0.1 4.9.1].each do |version|
        context "when using Yarn #{version}" do
          before do
            allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return([version, '', cmd_success])
            allow(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder') do
              ['', 'Usage Error: Couldn\'t find a configuration settings named "modules-folder"', cmd_failure]
            end
            allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::BERRY_SHELL_COMMAND) do
              [yarn_shell_command_output, '', cmd_success]
            end
          end

          it 'lists every package but the workspaces' do
            packages = subject.current_packages

            expect(packages.map { |package| [package.name, package.version] }).to eq [
              ['@types/jest', '26.0.24'],
              ['is-number', '7.0.0'],
              ['left-pad', '1.3.0'],
              ['react-dom', '18.2.0'],
              ['scheduler', '0.23.2'],
              ['typescript', '5.4.5']
            ]
            expect(packages.first.license_names_from_spec).to eq ['MIT']
            expect(packages.first.homepage).to eq 'https://github.com/DefinitelyTyped/DefinitelyTyped/tree/master/types/jest'
            expect(packages.first.install_path).to eq Pathname(root).join('node_modules', '@types/jest')
            expect(packages.last.license_names_from_spec).to eq ['Apache-2.0']
          end

          it 'leaves the license to be found in the package files when the manifest has none' do
            scheduler = subject.current_packages.find { |package| package.name == 'scheduler' }

            expect(scheduler.license_names_from_spec).to eq []
            expect(scheduler.homepage).to eq ''
          end

          context 'ignored_groups contains devDependencies' do
            subject { Yarn.new(project_path: Pathname(root), ignored_groups: 'devDependencies') }

            before do
              FileUtils.mkdir_p(File.join(root, 'packages/sub'))
              File.write(File.join(root, 'package.json'), { devDependencies: { 'left-pad' => '1.3.0' } }.to_json)
              File.write(File.join(root, 'packages/sub/package.json'),
                         { dependencies: { 'is-number' => '7.0.0' }, devDependencies: { '@types/jest' => '^26.0.23' } }.to_json)
            end

            it 'lists only the packages the workspaces depend on in production' do
              expect(subject.current_packages.map(&:name)).to match_array %w[is-number react-dom scheduler typescript]
            end
          end

          context 'when the shell command fails' do
            it 'an error is raised' do
              allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::BERRY_SHELL_COMMAND).and_return([nil, 'error', cmd_failure])

              expect { subject.current_packages }.to raise_error(/Command '#{Yarn::BERRY_SHELL_COMMAND}' failed to execute: error/)
            end
          end
        end
      end

      it 'displays packages as returned from "yarn list"' do
        allow(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder') do
          ["yarn_modules\n", '', cmd_success]
        end
        allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}") do
          [yarn1_shell_command_output, '', cmd_success]
        end

        expect(subject.current_packages.length).to eq 2
        expect(subject.current_packages.first.name).to eq '@sindresorhus/is'
        expect(subject.current_packages.first.version).to eq '0.7.0'
        expect(subject.current_packages.first.license_names_from_spec).to eq ['MIT']
        expect(subject.current_packages.first.homepage).to eq 'sindresorhus.com'
        expect(subject.current_packages.first.authors).to eq 'Sindre Sorhus'
        expect(subject.current_packages.first.install_path).to eq Pathname(root).join('yarn_modules', '@sindresorhus/is')
        expect(subject.current_packages.last.name).to eq 'yn'
        expect(subject.current_packages.last.version).to eq '2.0.0'
        expect(subject.current_packages.last.license_names_from_spec).to eq ['MIT']
        expect(subject.current_packages.last.homepage).to eq 'sindresorhus.com'
        expect(subject.current_packages.last.authors).to eq 'Sindre Sorhus'
        expect(subject.current_packages.last.install_path).to eq Pathname(root).join('yarn_modules', 'yn')
      end

      it 'uses node_modules as fallback for install path' do
        allow(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder') do
          ["undefined\n", '', cmd_success]
        end
        allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}") do
          [yarn1_shell_command_output, '', cmd_success]
        end

        expect(subject.current_packages.last.install_path).to eq Pathname(root).join('node_modules', 'yn')
      end

      it 'displays incompatible packages with license type unknown' do
        allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}") do
          ['{"type":"info","data":"fsevents@1.1.1: The platform \"linux\" is incompatible with this module."}
            {"type":"info","data":"\"fsevents@1.1.1\" is an optional dependency and failed compatibility check. Excluding it from installation."}', '', cmd_success]
        end

        expect(subject.current_packages.length).to eq 1
        expect(subject.current_packages.last.name).to eq 'fsevents'
        expect(subject.current_packages.last.version).to eq '1.1.1'
        expect(subject.current_packages.last.license_names_from_spec).to eq ['unknown']
      end

      it 'handles json with non-ascii characters' do
        allow(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder') do
          ['yarn_modules', '', cmd_success]
        end
        allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}") do
          [{
            'type' => 'table',
            'data' => {
              'body' => [['stack-trace', '0.0.10', 'MIT', 'git://github.com/felixge/node-stack-trace.git', 'https://github.com/felixgö/node-stack-trace', 'Felix Geisendörfer']],
              'head' => %w[Name Version License URL VendorUrl VendorName]
            }
          }.to_json, '', cmd_success]
        end

        expect(subject.current_packages.length).to eq 1
        expect(subject.current_packages.first.name).to eq 'stack-trace'
        expect(subject.current_packages.first.version).to eq '0.0.10'
        expect(subject.current_packages.first.license_names_from_spec).to eq ['MIT']
        expect(subject.current_packages.first.homepage).to eq 'https://github.com/felixg?/node-stack-trace'
      end

      context 'ignored_groups contains devDependencies' do
        subject { Yarn.new(project_path: Pathname(root), ignored_groups: 'devDependencies') }
        it 'should include a production flag' do
          expect(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder')
                                                     .and_return(['yarn_modules', '', cmd_success])
          expect(SharedHelpers::Cmd).to receive(:run).with("#{Yarn::SHELL_COMMAND} --production --no-progress --cwd #{Pathname(root)}")
                                                     .and_return([yarn1_shell_command_output, '', cmd_success])
          subject.current_packages
        end
      end

      context 'packages contain workspace-aggregator' do
        it 'should remove the package' do
          allow(SharedHelpers::Cmd).to receive(:run).with('yarn config get modules-folder') do
            ['yarn_modules', '', cmd_success]
          end
          allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}") do
            [{
              'type' => 'table',
              'data' => {
                'body' => [['workspace-aggregator-8e9c6710-d159-44a9-b7eb-78831eed0c59', '', 'UNKNOWN', 'Unknown', 'Unknown', 'Unknown'],
                           ['stack-trace', '0.0.10', 'MIT', 'git://github.com/felixge/node-stack-trace.git', 'https://github.com/felixgö/node-stack-trace', 'Felix Geisendörfer']],
                'head' => %w[Name Version License URL VendorUrl VendorName]
              }
            }.to_json, '', cmd_success]
          end

          expect(subject.current_packages.length).to eq 1
          expect(subject.current_packages.first.name).to eq 'stack-trace'
          expect(subject.current_packages.first.version).to eq '0.0.10'
          expect(subject.current_packages.first.license_names_from_spec).to eq ['MIT']
          expect(subject.current_packages.first.homepage).to eq 'https://github.com/felixg?/node-stack-trace'
        end
      end

      context 'when the shell command fails' do
        it 'an error is raised' do
          allow(SharedHelpers::Cmd).to receive(:run).with(Yarn::SHELL_COMMAND + " --no-progress --cwd #{Pathname(root)}").and_return([nil, 'error', cmd_failure])

          expect { subject.current_packages }.to raise_error(/Command 'yarn licenses list --recursive --json --no-progress --cwd #{Pathname(root)}' failed to execute: error/)
        end
      end
    end

    describe '.prepare_command' do
      include FakeFS::SpecHelpers
      before do
        FileUtils.mkdir_p(Dir.tmpdir)
        FileUtils.mkdir_p(root)
      end

      context 'when in a Yarn 1.x project' do
        before do
          allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return(['1.9.1', '', cmd_success])
        end

        subject { Yarn.new(project_path: Pathname(root), logger: double(:logger, active: nil)) }
        it 'returns the correct prepare method' do
          expect(subject.prepare_command).to eq('yarn install --ignore-engines --ignore-scripts')
        end
      end

      %w[2.1.9 3.5.9 4.9.1].each do |version|
        context "when in a Yarn #{version} project" do
          before do
            allow(SharedHelpers::Cmd).to receive(:run).with('yarn -v').and_return([version, '', cmd_success])
          end

          subject { Yarn.new(project_path: Pathname(root), logger: double(:logger, active: nil)) }
          it 'returns the correct prepare method' do
            expect(subject.prepare_command).to eq('yarn install')
          end
        end
      end
    end

    describe '.package_management_command' do
      it 'returns the correct package management command' do
        expect(subject.package_management_command).to eq('yarn')
      end
    end
  end
end
