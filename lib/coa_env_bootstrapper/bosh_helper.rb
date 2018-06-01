class CoaEnvBootstrapper
  module BoshHelper
    def upload_stemcell
      info = @prereqs["stemcell"]
      name = info["name"]
      version = info["version"]
      uri = info["uri"]
      sha = info["sha"]

      if stemcell_is_uploaded?(name, version)
        puts "Stemcell #{name}/#{version} already uploaded."
      else
        run_cmd "bosh -n upload-stemcell --sha1 #{sha} #{uri}", sourced: true
      end
    end

    def upload_cloud_config
      cloud_config_yml = File.join(@tmpdir, "cloud-config.yml")
      create_file_from_prereqs(cloud_config_yml, "cloud_config")
      run_cmd "bosh -n update-cloud-config #{cloud_config_yml}", sourced: true
    end

    def install_git_server
      if bosh_release_is_uploaded?("git-server", "3")
        puts "BOSH release git-server/3 already uploaded."
      else
        run_cmd "bosh upload-release --sha1 682a70517c495455f43545b9ae39d3f11d24d94c \
https://bosh.io/d/github.com/cloudfoundry-community/git-server-release?v=3", sourced: true
      end

      git_server_manifest = File.join(@tmpdir, "git_server_manifest.yml")
      create_file_from_prereqs(git_server_manifest, "git_server_manifest")

      run_cmd "bosh -n deploy -d git-server #{git_server_manifest} -v repos=[paas-templates,secrets]", sourced: true
    end


    def stemcell_is_uploaded?(name, version)
      run_cmd("bosh stemcells --column name --column version | cut -f1,2", sourced: true).
        split("\n").map(&:split).
        keep_if do |stemcell|
        stemcell[0] == name && stemcell[1].match(/#{version}\*{0,1}/)
      end.first
    end

    def bosh_release_is_uploaded?(name, version)
      run_cmd("bosh releases --column name --column version | cut -f1,2", sourced: true).
        split("\n").map(&:split).
        keep_if do |release|
        release[0] == name && release[1].match(/#{version}\*{0,1}/)
      end.first
    end

    def deployment_is_deployed?(deployment_name)
      run_cmd("bosh deployments --column name|cut -f1", sourced: true).split("\n").
        keep_if { |s| s.match(/#{deployment_name}\*{0,1}/) }.first
    end
  end
end
