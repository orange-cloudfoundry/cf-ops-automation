require 'spec_helper'
require 'git_modules'

describe GitModules do
  describe "#list" do
    let(:git_modules) { described_class.new('base_path') }

    context "when there is no .gitmodules file" do
      before do
        allow(File).to receive(:exist?).with('base_path/.gitmodules').
          and_return(false)
      end

      it "return an empty hash" do
        expect(git_modules.list).to eq({})
      end
    end

    context "when there is a .gitmodules file" do
      let(:gitmodules_path) { File.join(fixtures_dir('lib'), 'gitmodules') }

      before do
        allow(File).to receive(:exist?).with('base_path/.gitmodules').
          and_return(true)
        allow(File).to receive(:open).with('base_path/.gitmodules').
          and_return(File.open(gitmodules_path))
      end

      it "returns a hash" do
        expected_answer = {
          "plugins" => {
            "first-example"  => ["plugins/first-example"],
            "second-example" => ["plugins/second-example"],
            "third-example"  => ["plugins/third-example"]
          },
          "other-plugins" => {
            "fourth-example" => ["other-plugins/fourth-example"]
          }
        }
        expect(git_modules.list).to eq(expected_answer)
      end
    end
  end
end
