module ReferenceDatasetDocumentation
  class FileListWriter
    def initialize(generator)
      @generator = generator
    end

    def perform
      write_config_file_list
      write_template_file_list
    end

    private

    def write_config_file_list
      write_file_list(@generator.config_repo_path, @generator.config_repo_name, "config")
    end

    def write_template_file_list
      write_file_list(@generator.template_repo_path, @generator.template_repo_name, "template")
    end

    def write_file_list(repo_path, repo_name, name)
      Dir.chdir(File.join(repo_path, @generator.root_deployment_name)) do
        list = `find .`
        @generator.add("## The #{name} files", "")
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

    def pretty_filepath(path, repo_name)
      stripped_path = path.strip
      filename = extract_filename(stripped_path)
      return "" if filename[0] == "."
      prefix = extract_prefix(stripped_path)
      cleaned_path = clean_path(stripped_path)
      "#{prefix}* [#{filename}](/docs/reference_dataset/#{repo_name}/#{@generator.example_type}/#{@generator.root_deployment_name}/#{cleaned_path})"
    end

    def extract_filename(path)
      path.strip.split('/').last
    end

    def extract_prefix(path)
      path_items = path.strip.split('/')
      "  " * (path_items.size - 2)
    end

    def clean_path(path)
      path.strip.gsub(%r{^.\/}, "")
    end
  end
end
