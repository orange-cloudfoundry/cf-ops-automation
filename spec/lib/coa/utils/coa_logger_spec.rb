require 'rspec'
require 'coa/utils/coa_logger'
require 'pathname'

describe Coa::Utils::CoaLogger do
  context 'when custom log path is provided' do
    let(:coa_logger) { Class.new { include Coa::Utils::CoaLogger }.logger }
    let(:logger_tmpdir) { Dir.mktmpdir('coa_logger_') }
    let(:log_filepath) { logger_tmpdir }
    let(:log_file_pathname) { Pathname.new(log_filepath) }
    let(:log_file_relative_path) { log_file_pathname.relative_path_from(current_pathname) }
    let(:current_pathname) { Pathname.new(File.dirname(__FILE__)) }

    it 'creates log file at this path' do
      allow(ENV).to receive(:fetch).with("COA_LOG_PATH", "../../../log").and_return(log_file_relative_path)
      coa_logger.log_and_puts :info, 'my info message'

      expect(File).to exist(log_filepath)
    end
  end
end