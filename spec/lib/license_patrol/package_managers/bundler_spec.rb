# frozen_string_literal: true

require 'spec_helper'

module LicensePatrol
  describe Bundler do
    it_behaves_like 'a PackageManager'

    let(:definition) do
      double('definition', dependencies: [],
                           groups: %i[dev production],
                           specs_for: [
                             build_gemspec('gem1', '1.2.3'),
                             build_gemspec('gem2', '0.4.2')
                           ])
    end

    def build_gemspec(name, version, dependency = nil)
      Gem::Specification.new do |s|
        s.name = name
        s.version = version
        s.summary = 'summary'
        s.description = 'description'

        s.add_dependency dependency if dependency
      end
    end

    describe '.prepare_command' do
      before do
        allow(SecureRandom).to receive(:uuid).and_return('some-path')
      end

      context 'with ignored groups' do
        subject { Bundler.new(ignored_groups: Set.new(%w[dev test]), project_path: Pathname.new('.'), definition: definition) }
        it 'returns the correct prepare method' do
          expect(subject.prepare_command).to eq('bundle install --without dev test --path lf-bundler-gems-some-path')
        end
      end

      context 'without ignored groups' do
        subject { Bundler.new(ignored_groups: Set.new, project_path: Pathname.new('.'), definition: definition) }
        it 'returns the correct prepare method' do
          expect(subject.prepare_command).to eq('bundle install  --path lf-bundler-gems-some-path')
        end
      end
    end

    describe '.current_packages' do
      subject do
        Bundler.new(ignored_groups: Set.new(%w[dev test]), project_path: Pathname.new('.'), definition: definition).current_packages
      end

      it 'should have 2 dependencies' do
        expect(subject.size).to eq(2)
      end

      context 'when initialized with a parent and child gem' do
        before do
          allow(definition).to receive(:specs_for).with([:production]).and_return([
                                                                                    build_gemspec('gem1', '1.2.3', 'gem2'),
                                                                                    build_gemspec('gem2', '0.4.2', 'gem3')
                                                                                  ])
        end

        it 'should update the child dependency with its parent data' do
          gem1 = subject.first

          expect(gem1.children).to eq(['gem2'])
        end
      end
    end

    describe 'specifying a custom gemfile' do
      let(:custom_gemfile) { fixture_path('custom_gemfile') }

      subject do
        Bundler.new(project_path: custom_gemfile, ignored_groups: Set.new(%w[dev test]))
      end

      context 'when actually not specifying' do
        around do |example|
          old_var = ENV['BUNDLE_GEMFILE']
          ENV.delete 'BUNDLE_GEMFILE'
          example.run
          ENV['BUNDLE_GEMFILE'] = old_var
        end

        it 'defaults to Gemfile/Gemfile.lock' do
          expect(::Bundler::Definition).to receive(:build).with(custom_gemfile.join('Gemfile'), custom_gemfile.join('Gemfile.lock'), nil).and_return(definition)
          expect(subject.current_packages).to_not be_empty
        end
      end

      context 'with the BUNDLE_GEMFILE environment variable set' do
        around do |example|
          old_var = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = 'Gemfile-other'
          example.run
          ENV['BUNDLE_GEMFILE'] = old_var
        end

        it 'uses the BUNDLE_GEMFILE variable to identify the gemfile' do
          expect(::Bundler::Definition).to receive(:build).with(custom_gemfile.join('Gemfile-other'), custom_gemfile.join('Gemfile-other.lock'), nil).and_return(definition)
          expect(subject.current_packages).to_not be_empty
        end
      end

      context 'with the BUNDLE_GEMFILE environment variable set to a project nested directory' do
        around do |example|
          old_var = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = 'gemfiles/nested.gemfile'
          example.run
          ENV['BUNDLE_GEMFILE'] = old_var
        end

        it 'uses the BUNDLE_GEMFILE variable to identify the gemfile' do
          expect(::Bundler::Definition).to receive(:build).with(custom_gemfile.join('gemfiles/nested.gemfile'), custom_gemfile.join('gemfiles/nested.gemfile.lock'), nil).and_return(definition)
          expect(subject.current_packages).to_not be_empty
        end

        it 'points BUNDLE_GEMFILE to the gemfile in the project while reading it' do
          expect(::Bundler::Definition).to receive(:build) do
            expect(ENV['BUNDLE_GEMFILE']).to eq(custom_gemfile.join('gemfiles/nested.gemfile').to_s)
            definition
          end
          subject.current_packages
        end

        it 'restores BUNDLE_GEMFILE afterwards' do
          allow(::Bundler::Definition).to receive(:build).and_return(definition)
          subject.current_packages
          expect(ENV['BUNDLE_GEMFILE']).to eq('gemfiles/nested.gemfile')
        end
      end

      context 'with the BUNDLE_GEMFILE environment variable set to an absolute path inside the project (as through bundle exec)' do
        around do |example|
          old_var = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = custom_gemfile.join('gemfiles/nested.gemfile').to_s
          example.run
          ENV['BUNDLE_GEMFILE'] = old_var
        end

        it 'uses the BUNDLE_GEMFILE variable to identify the gemfile' do
          expect(::Bundler::Definition).to receive(:build).with(custom_gemfile.join('gemfiles/nested.gemfile'), custom_gemfile.join('gemfiles/nested.gemfile.lock'), nil).and_return(definition)
          expect(subject.current_packages).to_not be_empty
        end

        it 'points BUNDLE_GEMFILE to the gemfile in the project while reading it' do
          expect(::Bundler::Definition).to receive(:build) do
            expect(ENV['BUNDLE_GEMFILE']).to eq(custom_gemfile.join('gemfiles/nested.gemfile').to_s)
            definition
          end
          subject.current_packages
        end
      end

      context 'with the BUNDLE_GEMFILE environment variable set to an absolute path outside the project (as through bundle exec with --project_path)' do
        around do |example|
          old_var = ENV['BUNDLE_GEMFILE']
          ENV['BUNDLE_GEMFILE'] = '/some/other/project/Gemfile-other'
          example.run
          ENV['BUNDLE_GEMFILE'] = old_var
        end

        it 'uses the gemfile with the same name in the project' do
          expect(::Bundler::Definition).to receive(:build).with(custom_gemfile.join('Gemfile-other'), custom_gemfile.join('Gemfile-other.lock'), nil).and_return(definition)
          expect(subject.current_packages).to_not be_empty
        end
      end
    end

    describe 'reading the bundler config of a nested gemfile' do
      let(:project_path) { Pathname(Dir.mktmpdir) }

      around do |example|
        old_var = ENV['BUNDLE_GEMFILE']
        ENV['BUNDLE_GEMFILE'] = 'gemfiles/nested.gemfile'
        example.run
        ENV['BUNDLE_GEMFILE'] = old_var
        FileUtils.rm_rf(project_path)
      end

      before do
        FileUtils.mkdir_p(project_path.join('gemfiles/.bundle'))
        FileUtils.touch(project_path.join('gemfiles/nested.gemfile'))
        FileUtils.touch(project_path.join('gemfiles/nested.gemfile.lock'))
        allow(::Bundler::Definition).to receive(:build).and_return(definition)
      end

      subject { Bundler.new(project_path: project_path, ignored_groups: Set.new) }

      it 'configures bundler when the config next to the gemfile sets BUNDLE_PATH (vendored gems)' do
        File.write(project_path.join('gemfiles/.bundle/config'), "---\nBUNDLE_PATH: \"vendor/bundle\"\n")
        expect(::Bundler).to receive(:reset!)
        expect(::Bundler).to receive(:configure)
        subject.current_packages
      end

      it 'does not configure bundler otherwise' do
        expect(::Bundler).to_not receive(:reset!)
        expect(::Bundler).to_not receive(:configure)
        subject.current_packages
      end
    end
  end
end
