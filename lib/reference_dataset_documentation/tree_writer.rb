module ReferenceDatasetDocumentation
  class TreeWriter
    def initialize(generator)
      @generator = generator
    end

    def perform
      write_config_repo_tree
      write_template_repo_tree
    end

    private

    def write_config_repo_tree
      write_repo_tree(@generator.config_repo_path, "config")
    end

    def write_template_repo_tree
      write_repo_tree(@generator.template_repo_path, "template")
    end

    def write_repo_root_level_tree(repo_path, name)
      Dir.chdir(repo_path) do
        list = `tree --noreport -L 1`

        @generator.add("## The #{name} repo", "", "### root level overview", "", "```bash", list, "```", "")
      end
    end

    def write_repo_tree(repo_path, name)
      write_repo_root_level_tree(repo_path, name)

      Dir.chdir(repo_path) do
        list = "Inactive deployment: config dir for #{@generator.root_deployment_name} does not exist."
        if Dir.exist?(@generator.root_deployment_name)
          list = `tree --noreport #{@generator.root_deployment_name}`
        end
        @generator.add("### #{@generator.root_deployment_name} overview", "", "```bash", list, "```", "")
      end
    end
  end
end
