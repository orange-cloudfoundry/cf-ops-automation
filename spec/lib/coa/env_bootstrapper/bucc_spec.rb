require 'spec_helper'
require 'coa/constants'
require 'coa/env_bootstrapper/bucc'

describe Coa::EnvBootstrapper::Bucc do
  let(:cli_path) { "#{Coa::Constants::PROJECT_ROOT_DIR}/bin/bucc/bin/bucc" }

  describe '#deploy_transient_infra' do
    context "with no given bucc config" do
      let(:bucc) { described_class.new({}) }

      it "errors"
    end

    context "with a given bucc config" do
      let(:prereqs) do
        { "cpi" => "virtualbox", "cpi_specific_options" => "--verbose" }
      end
      let(:bucc) { described_class.new(prereqs) }

      it "runs a bucc command with the config" do
        allow(bucc).to receive(:run_cmd)

        bucc.deploy_transient_infra

        expect(bucc).to have_received(:run_cmd).
          with("#{cli_path} up --cpi virtualbox --verbose --lite --debug")
      end
    end

    context "when the deployment is not successful"
  end

  describe '#vars' do
    let(:prereqs) do
      { "cpi" => "virtualbox", "cpi_specific_options" => "--verbose", "bin_path" => "/path/to/bucc/bin" }
    end
    let(:bucc) { described_class.new(prereqs) }

    context "when bucc vars returns a valid yaml" do
      let(:bucc_var_answer) do
        "director_name: bucc\ninternal_cidr: 192.168.50.0/24\ninternal_gw: 192.168.50.1\ninternal_ip: 192.168.50.6"
      end
      let(:expected_answer) do
        {
          "director_name" => "bucc",
          "internal_cidr" => "192.168.50.0/24",
          "internal_gw"   => "192.168.50.1",
          "internal_ip"   => "192.168.50.6"
        }
      end

      it "loads the result of the yaml" do
        allow(bucc).to receive(:run_cmd).
          with("#{cli_path} vars", verbose: false).
          and_return(bucc_var_answer)

        expect(bucc.vars).to eq(expected_answer)
      end
    end

    context "when bucc vars returns an invalid yaml" do
      let(:bucc_var_answer) { "zsh: command not found: bucc" }

      it "errors" do
        allow(bucc).to receive(:run_cmd).
          with("#{cli_path} vars", verbose: false).and_return(bucc_var_answer)

        expect { bucc.vars }.
          to raise_error(Coa::EnvBootstrapper::BuccCommandError)
      end
    end
  end
end
