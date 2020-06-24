require_relative './readme_author'

module Coa
  module ReferenceDatasetDocumentation
    # This class helps us writting the file list in form of a tree.
    class TreeWriter
      include Coa::ReferenceDatasetDocumentation::ReadmeAuthor

      def perform
        write_config_repo_tree
        write_template_repo_tree
      end

      private

      def write_config_repo_tree
        write_repo_tree(config_repo_path, "config")
      end

      def write_template_repo_tree
        write_repo_tree(template_repo_path, "template")
      end

      def write_repo_root_level_tree(repo_path, name)
        list = ""
        Dir.chdir(repo_path) do
          list = `tree --noreport -L 1`
        end

        write("## The #{name} repo", "", "### root level overview", "", "```bash", list, "```", "")
      end

      def write_repo_tree(repo_path, name)
        write_repo_root_level_tree(repo_path, name)
        list = ""

        Dir.chdir(repo_path) do
          list = "Inactive deployment: config dir for #{root_deployment_name} does not exist."
          list = `tree --noreport #{root_deployment_name}` if Dir.exist?(root_deployment_name)
        end

        write("### #{root_deployment_name} overview", "", "```bash", list, "```", "")
      end
    end
  end
end
