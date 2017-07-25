
class GitModules

  def self.list(base_path)
    git_submodules = {}

    gitmodules = File.open("#{base_path}/.gitmodules") if File.exist? "#{base_path}/.gitmodules"
    gitmodules
        &.select { |line| line.strip!.start_with?('path =') }
        &.each { |path| path[0..6] = '' }
        &.each { |path|
      parsed_path=path.split('/')
      if parsed_path.length > 2
        current_depls=parsed_path[0]
        current_deployment=parsed_path[1]
        item = { current_deployment => [path] }
        # puts item
        unless git_submodules[current_depls]
          # puts "init #{current_depls}"
          git_submodules[current_depls] = {}
        end
        if !git_submodules[current_depls][current_deployment]
          # puts "init #{current_depls} - #{current_deployment}"
          git_submodules[current_depls].merge! item
        else
          # puts "add #{current_depls} - #{current_deployment}: #{git_submodules[current_depls][current_deployment]} ## #{git_submodules}"
          # git_submodules.merge!(git_submodules[current_depls][current_deployment])
          git_submodules[current_depls][current_deployment] << path
        end
      end
    }
    gitmodules&.close
    git_submodules

  end


end