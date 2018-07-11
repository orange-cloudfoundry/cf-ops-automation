require 'spec_helper'
require 'coa_env_bootstrapper/env_creator_adapter'

describe CoaEnvBootstrapper::EnvCreatorAdapter do
  describe '.new' do
    context "when the adapter is exists" do
      let(:bucc_prereqs) { { "cpi" => "virtualbox" } }
      let(:prereqs) { { "bucc" => bucc_prereqs } }
      let(:adapter_name) { "bucc" }

      it "loads the adapter with the prereqs" do
        adapter = described_class.new(adapter_name, prereqs)
        adapter_instance = adapter.adapter

        expect(adapter_instance.class).to eq(CoaEnvBootstrapper::Bucc)
        expect(adapter_instance.prereqs).to eq(bucc_prereqs)
      end
    end

    context "when another adapter is given" do
      let(:adapter_name) { "non_existant" }

      it "errors" do
        expect { described_class.new(adapter_name, {}) }.
          to raise_error(CoaEnvBootstrapper::EnvCreatorAdapterNotImplementedError)
      end
    end
  end

  describe '#vars'
  describe '#concourse_target'
end
