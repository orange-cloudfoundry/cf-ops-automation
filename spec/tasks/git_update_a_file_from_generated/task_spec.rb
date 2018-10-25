# require 'spec_helper.rb'
require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'git'

describe 'git_update_a_file_from_generated task' do
  context 'when executed' do
    after(:context) do
      FileUtils.rm_rf @generated_resource
      FileUtils.rm_rf @updated_git_resource
      FileUtils.rm_rf @reference_resource
    end

    before(:context) do
      @reference_resource = Dir.mktmpdir
      @updated_git_resource = Dir.mktmpdir
      @generated_resource = Dir.mktmpdir
      File.open(File.join(@generated_resource, 'updated_file.txt'), 'w') { |file| file.write('updated') }

      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'reference-resource', '.'), @reference_resource)
      repo = Git.init(@reference_resource)
      repo.config('user.name', 'COA CI')
      repo.config('user.email', 'coa-ci@orange.com')
      repo.add
      repo.commit('initialize repository')
      @output = execute('--include-ignored -c concourse/tasks/git_update_a_file_from_generated.yml ' \
        "-i reference-resource=#{@reference_resource} " \
        "-i generated-resource=#{@generated_resource} " \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'COMMIT_MESSAGE' => "'my commit message'",
                        'OLD_FILE' => 'coa/pipelines/deployed/to_be_updated_file.txt',
                        'NEW_FILE' => 'updated_file.txt')
    end

    it 'updates files in output dir' do
      expected_files = [File.join(@updated_git_resource, "coa/pipelines/deployed/unchanged_file.txt"), File.join(@updated_git_resource, "coa/pipelines/deployed/to_be_updated_file.txt")]
      expect(Dir[File.join(@updated_git_resource, 'coa/pipelines/deployed/') + '*']).to match(expected_files)
    end

    it 'updates file content' do
      updated_content = File.read(File.join(@updated_git_resource, "coa/pipelines/deployed/to_be_updated_file.txt"))
      expect(updated_content).to eq('updated')
    end

    it 'sets a valid commit message' do
      repo = Git.open(@updated_git_resource)
      commit = repo.log.first
      expect(commit.message).to eq('my commit message')
    end
  end

  context 'when executed with meta' do
    after(:context) do
      FileUtils.rm_rf @generated_resource
      FileUtils.rm_rf @updated_git_resource
      FileUtils.rm_rf @reference_resource
    end

    before(:context) do
      @reference_resource = Dir.mktmpdir
      @updated_git_resource = Dir.mktmpdir
      @generated_resource = Dir.mktmpdir
      File.open(File.join(@generated_resource, 'updated_file.txt'), 'w') { |file| file.write('updated') }

      FileUtils.cp_r(File.join(File.dirname(__FILE__), 'reference-resource', '.'), @reference_resource)
      repo = Git.init(@reference_resource)
      repo.config('user.name', 'COA CI')
      repo.config('user.email', 'coa-ci@orange.com')
      repo.add
      repo.commit('initialize repository')
      @output = execute('--include-ignored -c concourse/tasks/git_update_a_file_from_generated.yml ' \
        "-i reference-resource=#{@reference_resource} " \
        "-i generated-resource=#{@generated_resource} " \
        "-i concourse-meta=#{File.join(File.dirname(__FILE__), 'meta')} " \
        "-o updated-git-resource=#{@updated_git_resource} ",
                        'COMMIT_MESSAGE' => "'my commit message'",
                        'OLD_FILE' => 'coa/pipelines/deployed/to_be_updated_file.txt',
                        'NEW_FILE' => 'updated_file.txt')
    end

    it 'updates files in output dir' do
      expected_files = [File.join(@updated_git_resource, "coa/pipelines/deployed/unchanged_file.txt"), File.join(@updated_git_resource, "coa/pipelines/deployed/to_be_updated_file.txt")]
      expect(Dir[File.join(@updated_git_resource, 'coa/pipelines/deployed/') + '*']).to match(expected_files)
    end

    it 'updates file content' do
      updated_content = File.read(File.join(@updated_git_resource, "coa/pipelines/deployed/to_be_updated_file.txt"))
      expect(updated_content).to eq('updated')
    end


    it 'sets a valid commit message' do
      repo = Git.open(@updated_git_resource)
      commit = repo.log.first
      expect(commit.message).to eq("my commit message\n\nCreated by main/pipeline/job/build-name - 1")
    end
  end
end
