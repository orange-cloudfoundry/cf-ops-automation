require_relative './helpers/file_list_writer_helpers'
require_relative './writer'
require_relative '../constants'

module Coa
  module ReferenceDatasetDocumentation
    # This class can write a list of configs and templates files for a given
    # root deployment.
    class FileListWriter < Writer
      include Coa::Constants
      include Helpers::FileListWriterHelpers

      def write(config_repo_name:, template_repo_name:)
        write_config_file_list(config_repo_name)
        write_template_file_list(template_repo_name)
      end

      private

      def write_config_file_list(config_repo_name)
        write_root_level_files_and_dirs(config_repo_path, config_repo_name, "config")
        write_file_list(config_repo_path, config_repo_name, root_deployment_name)
        write_file_list(config_repo_path, "shared", "shared")
      end

      def write_template_file_list(template_repo_name)
        write_root_level_files_and_dirs(template_repo_path, template_repo_name, "template")
        write_file_list(template_repo_path, template_repo_name, root_deployment_name)
      end

      def write_root_level_files_and_dirs(repo_path, repo_name, name)
        list = ""
        Dir.chdir(repo_path) do
          list = `find . -maxdepth 1|sort`
        end

        add("## The #{name} files", "")
        add("### The root #{name} files", "")
        pretty_list(list, repo_name)
        add ""
      end

      def write_file_list(repo_path, repo_name, root_deployment_name)
        list = ''
        Dir.chdir(repo_path) do
          if Dir.exist?(root_deployment_name)
            list = `find #{root_deployment_name}|sort`
          end
        end

        add("### The #{root_deployment_name} files", "")
        pretty_list(list, repo_name)
        add ""
      end

      def pretty_list(list, repo_name)
        new_list = []

        list.each_line do |line|
          new_list << pretty_filepath(line, repo_name)
        end

        new_list.delete_if(&:empty?).each { |item| add(item) }
      end
    end
  end
end
