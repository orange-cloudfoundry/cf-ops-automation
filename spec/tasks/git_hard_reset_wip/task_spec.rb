# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'git_hard reset_wip task' do
  before(:context) do
    @git_test_reference_repo = 'https://github.com/orange-cloudfoundry/cf-ops-automation-git-reset-wip-it'
    @reference_repo_dir = Dir.mktmpdir
    out, err, status = Open3.capture3("git clone #{@git_test_reference_repo} #{@reference_repo_dir}")
    expect(err).to eq("Cloning into '#{@reference_repo_dir}'...\n")
    @coa_dir = Dir.mktmpdir
    tasks_dir = File.join('concourse', 'tasks')
    current_task_dir = File.join(tasks_dir, 'git_hard_reset_wip')
    FileUtils.mkdir_p(File.join(@coa_dir, tasks_dir), verbose: true)
    FileUtils.cp_r(current_task_dir, File.join(@coa_dir, tasks_dir), verbose: true)
    workaround_to_ensure_cp_is_finished = Dir[@coa_dir+'/**/*'].size
    puts "Coa files count: #{workaround_to_ensure_cp_is_finished}"
  end

  after(:context) do
    FileUtils.rm_rf @reference_repo_dir if File.exist?(@reference_repo_dir.to_s)
    FileUtils.rm_rf @result if File.exist?(@result.to_s)
    FileUtils.rm_rf @coa_dir if File.exist?(@coa_dir.to_s)
  end

  context 'when executed with develop as base branch' do
    before(:context) do
      @updated_git_resource = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_hard_reset_wip/task.yml ' \
        "-i reference-resource=#{@reference_repo_dir} " \
        "-i cf-ops-automation=#{@coa_dir} " \
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

  context 'when executed with main as base branch' do
    before(:context) do
      @updated_git_resource = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_hard_reset_wip/task.yml ' \
        "-i reference-resource=#{@reference_repo_dir} " \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'GIT_BRANCH_FILTER' => '"unknown-branch"',
                        'GIT_CHECKOUT_BRANCH' => 'main')
    end

    after(:context) do
      FileUtils.rm_rf @updated_git_resource
    end

    it 'reset main branch' do
      expect(@output).to include("Reset branch 'main'", "Your branch is up to date with 'origin/main'")
    end

    it 'contains master.md file' do
      expect(File).to exist(File.join(@updated_git_resource, 'master.md'))
    end
  end
end
