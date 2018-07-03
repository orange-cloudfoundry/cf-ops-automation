require_relative './helpers/file_list_writer_helpers'

module ReferenceDatasetDocumentation
  class FileListWriter
    include Helpers::FileListWriterHelpers

    def initialize(generator)
      @generator = generator
    end

    def perform
      write_config_file_list
      write_template_file_list
    end

    private

    def write_config_file_list
      write_root_level_files_and_dirs(@generator.config_repo_path, @generator.config_repo_name, "config")
      write_file_list(@generator.config_repo_path, @generator.config_repo_name, @generator.root_deployment_name)
      write_file_list(@generator.config_repo_path, "shared", "shared")
    end

    def write_template_file_list
      write_root_level_files_and_dirs(@generator.template_repo_path, @generator.template_repo_name, "template")
      write_file_list(@generator.template_repo_path, @generator.template_repo_name, @generator.root_deployment_name)
    end

    def write_root_level_files_and_dirs(repo_path, repo_name, name)
      Dir.chdir(repo_path) do
        list = `find . -maxdepth 1|sort`
        @generator.add("## The #{name} files", "")
        @generator.add("### The root #{name} files", "")
        pretty_list(list, repo_name)
        @generator.add ""
      end
    end

    def write_file_list(repo_path, repo_name, root_deployment_name)
      Dir.chdir(repo_path) do
        list = ''
        if Dir.exist?(root_deployment_name)
          list = `find #{root_deployment_name}|sort`
        end

        @generator.add("### The #{root_deployment_name} files", "")
        pretty_list(list, repo_name)
        @generator.add ""
      end
    end

    def pretty_list(list, repo_name)
      new_list = []

      list.each_line do |line|
        new_list << pretty_filepath(line, repo_name)
      end

      new_list.delete_if(&:empty?).each { |item| @generator.add(item) }
    end
  end
end
