require 'rspec'
require 'coa/utils/coa_logger'
require 'pathname'

describe Coa::Utils::CoaLogger do
  context 'when custom log path is provided' do
    let(:coa_logger) { Class.new { include Coa::Utils::CoaLogger }.logger }
    let(:logger_tmpdir) { Dir.mktmpdir('coa_logger_') }
    let(:log_filepath) { logger_tmpdir }
    let(:root_path) { Pathname.new('/') }
    let(:current_pathname) { Pathname.new(File.dirname(__FILE__)) }
    let(:current_relative_pathname) { root_path.relative_path_from(current_pathname) }
    let(:coa_log_path) { File.join current_relative_pathname, log_filepath }

    it 'creates log file at this path' do
      allow(ENV).to receive(:fetch).with("COA_LOG_PATH", "../../../log").and_return(coa_log_path)
      coa_logger.log_and_puts :info, 'my info message'

      expect(File).to exist(log_filepath)
    end
  end
end