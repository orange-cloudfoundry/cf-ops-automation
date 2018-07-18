# encoding: utf-8
# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'git_reset_wip task' do
  before(:context) do
    @git_test_reference_repo = 'https://github.com/orange-cloudfoundry/cf-ops-automation-git-reset-wip-it'
    dest_dir = 'spec/tasks/git_reset_wip/reference-resource'
    FileUtils.rm_rf dest_dir if Dir.exist? dest_dir
    out, err, status = Open3.capture3("git clone #{@git_test_reference_repo} #{dest_dir}")
    expect(err).to eq("Cloning into 'spec/tasks/git_reset_wip/reference-resource'...\n")
  end

  after(:context) do
    FileUtils.rm_rf @git_test_reference_repo
  end


  context 'when executed with develop as base branch' do

    before(:context) do
      @updated_git_resource = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_reset_wip.yml ' \
        '-i reference-resource=spec/tasks/git_reset_wip/reference-resource ' \
        "-o updated-git-resource=#{@updated_git_resource} ",
        'SKIP_SSL_VERIFICATION' =>'true',
        'GIT_BRANCH_FILTER' => '"WIP-* wip-* feature-* Feature-*"')
    end

    after(:context) do
      FileUtils.rm_rf @updated_git_resource
    end

    it 'only merges branches matching filter' do
      expect(@output).to include('Processing wip-1').and \
        include('Processing WIP-2').and \
        include('Processing feature-1').and \
        include('Processing Feature-2').and \
        include("Switched to a new branch 'develop'")
    end

    %w[develop feature-1 Feature-2 wip-1 WIP-2].each do |merged_file|
      it "contains #{merged_file} file" do
        expect(File).to exist(File.join(@updated_git_resource, "#{merged_file}.md"))
      end


    end

    it 'does not contain files from a-branch' do
      expect(File).not_to exist(File.join(@updated_git_resource, 'a-branch.md'))
    end

    it 'contains reset timestamp' do
      expect(File).to exist(File.join(@updated_git_resource, ".last-reset"))
    end

    context 'when skip_ssl is enabled' do
      it 'does not check ssl certificates' do
        expect(@output).to include('Skipping ssl verification')
      end
    end

  end

  context 'when executed with master as base branch' do

    before(:context) do
      @updated_git_resource = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_reset_wip.yml ' \
        '-i reference-resource=spec/tasks/git_reset_wip/reference-resource ' \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'GIT_BRANCH_FILTER' => '"unknown-branch"',
                        'GIT_CHECKOUT_BRANCH' => 'master')
    end

    after(:context) do
      FileUtils.rm_rf @updated_git_resource
    end

    it 'reset master branch' do
      expect(@output).to include("Reset branch 'master'", "Your branch is up-to-date with 'origin/master'")
    end

    it 'contains master.md file' do
      expect(File).to exist(File.join(@updated_git_resource, 'master.md'))
    end

  end

end
