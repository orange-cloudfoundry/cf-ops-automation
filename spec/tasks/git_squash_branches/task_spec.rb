# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'git_squash_branches task' do
  before(:context) do
    @git_test_reference_repo = 'https://github.com/orange-cloudfoundry/cf-ops-automation-git-reset-wip-it'
    @reference_repo_dir = 'spec/tasks/git_squash_branches/reference-resource'
    FileUtils.rm_rf @reference_repo_dir if Dir.exist? @reference_repo_dir
    out, err, status = Open3.capture3("git clone #{@git_test_reference_repo} #{@reference_repo_dir}")
    expect(err).to eq("Cloning into 'spec/tasks/git_squash_branches/reference-resource'...\n")
    @coa_dir = Dir.mktmpdir
    tasks_dir = File.join('concourse', 'tasks')
    current_task_dir = File.join(tasks_dir, 'git_squash_branches')
    FileUtils.mkdir_p(File.join(@coa_dir, tasks_dir), verbose: true)
    FileUtils.cp_r(current_task_dir, File.join(@coa_dir, tasks_dir), verbose: true)
  end

  after(:context) do
    FileUtils.rm_rf @reference_repo_dir
  end

  context 'when executed with develop as base branch' do
    before(:context) do
      @updated_git_resource = Dir.mktmpdir
      @logs = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_squash_branches/task.yml ' \
        '-i reference-resource=spec/tasks/git_squash_branches/reference-resource ' \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-o logs=#{@logs} " \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'SKIP_SSL_VERIFICATION' => 'true',
                        'GIT_BRANCH_FILTER' => '\"WIP-* wip-* feature-* Feature-*\"')
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

    it 'contains reset timestamps' do
      expect(File).to exist(File.join(@updated_git_resource, ".last-reset")).and \
        exist(File.join(@updated_git_resource, "Feature-2", ".last-reset"))
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
      @logs = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_squash_branches/task.yml ' \
        '-i reference-resource=spec/tasks/git_squash_branches/reference-resource ' \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-o logs=#{@logs} " \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'GIT_BRANCH_FILTER' => '"unknown-branch"',
                        'GIT_CHECKOUT_BRANCH' => 'master')
    end

    after(:context) do
      FileUtils.rm_rf @updated_git_resource
    end

    it 'reset master branch' do
      expect(@output).to include("Reset branch 'master'", "Your branch is up to date with 'origin/master'")
    end

    it 'contains master.md file' do
      expect(File).to exist(File.join(@updated_git_resource, 'master.md'))
    end
  end
end
