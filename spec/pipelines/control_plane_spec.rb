require 'spec_helper'
require 'tmpdir'
require 'yaml'
require_relative '../tasks/task_spec_helper'

describe 'control plane pipeline spec' do
  let(:pipeline_file) { File.join('concourse', 'pipelines', 'control-plane.yml') }
  let(:control_plane_pipeline) { YAML.load_file(pipeline_file, aliases: true) }
  let(:control_plane_jobs) { control_plane_pipeline['jobs'] }
  let(:control_plane_resources) { control_plane_pipeline['resources'] }

  context 'when checking pipelines definition' do
    let(:expected_jobs) { %w[detect-paas-templates-scanned-changes load-generated-pipelines manual-reset-avoid-please manual-setup on-git-commit push-changes reset-secrets-pipeline-generation save-deployed-pipelines] }

    it 'has expected jobs' do
      jobs = control_plane_jobs.flat_map { |item| item['name'] }.sort
      expect(jobs).to eq(expected_jobs)
    end

    it 'has expected  resources' do
      expected_resources = %w[cf-ops-automation concourse-audit-trail concourse-meta concourse-micro concourse-micro-legacy failure-alert paas-templates-full paas-templates-scanned paas-templates-versions secrets-generated-pipelines secrets-writer]
      resources = control_plane_resources.flat_map { |item| item['name'] }.sort
      expect(resources).to eq(expected_resources)
    end
  end
end
