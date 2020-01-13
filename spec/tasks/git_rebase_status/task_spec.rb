# encoding: utf-8

# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'

describe 'git_rebase_status task' do
  before(:context) do
    @git_test_reference_repo = 'https://github.com/orange-cloudfoundry/cf-ops-automation-git-reset-wip-it'
    @reference_repo_dir = Dir.mktmpdir
    out, err, status = Open3.capture3("git clone #{@git_test_reference_repo} #{@reference_repo_dir}")
    expect(err).to eq("Cloning into '#{@reference_repo_dir}'...\n")
    @coa_dir = Dir.mktmpdir
    FileUtils.cp_r('concourse', @coa_dir)
  end

  after(:context) do
    FileUtils.rm_rf @reference_repo_dir if File.exist?(@reference_repo_dir.to_s)
    FileUtils.rm_rf @result if File.exist?(@result.to_s)
    FileUtils.rm_rf @coa_dir if File.exist?(@coa_dir.to_s)
  end

  context 'when executed' do
    before(:context) do
      @result = Dir.mktmpdir

      @output = execute('--include-ignored -c concourse/tasks/git_rebase_status/task.yml ' \
        "-i reference-resource=#{@reference_repo_dir} " \
        "-i cf-ops-automation=#{@coa_dir} " \
        "-o result=#{@result} ",
                        'SKIP_SSL_VERIFICATION' => 'true',
                        'GIT_BRANCH_FILTER' => '\"WIP-* wip-* feature-* Feature-*\"')
    end

    after(:context) do
      FileUtils.rm_rf @result
    end

    it 'checks rebase for branches matching filter' do
      expect(@output).to include('Processing wip-1').and \
        include('Processing WIP-2').and \
          include('Processing feature-1').and \
            include('Processing Feature-2').and \
              include("Reference head selected: 67b3f218859151bca33668748dd70265f83c61c1")
    end

    it 'does not check unmatched branches' do
      expect(@output).not_to include('Processing a-branch')
    end

    context 'when skip_ssl is enabled' do
      it 'does not check ssl certificates' do
        expect(@output).to include('Skipping ssl verification')
      end
    end
  end
end
