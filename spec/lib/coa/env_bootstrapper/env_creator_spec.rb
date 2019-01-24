require 'spec_helper'
require 'coa/env_bootstrapper/env_creator'

describe Coa::EnvBootstrapper::EnvCreator do
  describe '.new' do
    context "when prereqs with bucc are given" do
      let(:prereqs) { Coa::EnvBootstrapper::Prereqs.new("bucc" => {}) }
      let(:bucc) { Coa::EnvBootstrapper::Bucc.new(prereqs.bucc) }

      it "loads the adapter with the prereqs" do
        allow(Coa::EnvBootstrapper::Bucc).to receive(:new).and_return(bucc)

        end_creator = described_class.new(prereqs)

        expect(end_creator.adapter).to eq(bucc)
        expect(Coa::EnvBootstrapper::Bucc).to have_received(:new).
          with(prereqs.bucc)
      end
    end

    context "when no prereqs are given" do
      it "create an empty env creator" do
        env_creator = described_class.new
        expect(env_creator.adapter).to be_a(Coa::EnvBootstrapper::EmptyEnvCreator)
      end
    end
  end

  describe '#vars'
end
