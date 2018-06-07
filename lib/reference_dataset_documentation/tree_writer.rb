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

    def write_repo_tree(repo_path, name)
      Dir.chdir(File.join(repo_path, @generator.root_deployment_name)) do
        list = `tree --noreport .`

        @generator.add("## The #{name} repo", "", "```bash", list, "```", "")
      end
    end
  end
end
