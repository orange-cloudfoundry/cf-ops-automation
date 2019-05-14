require 'rspec'
require 'coa/utils/coa_logger'

describe Coa::Utils::CoaLogger do
  context 'when condition' do
    let(:logger_tmpdir) { Dir.mktmpdir('coa_logger_') }
    let(:log_filepath) { logger_tmpdir }
    let(:coa_logger) { Class.new { include Coa::Utils::CoaLogger }.logger }
    let(:current_file_dir) { File.dirname(__FILE__) }
    let(:coa_root_dir) { File.absolute_path(File.join(current_file_dir, '..', '..', '..', '..')) }
    let(:coa_logger_dir) { File.join(coa_root_dir, 'lib', 'coa', 'utils') }

    it 'succeeds' do
      allow(ENV).to receive(:fetch).with("COA_LOG_PATH", coa_logger_dir + "/../../../log").and_return(log_filepath)
      coa_logger.log_and_puts :info, 'my info message'

      expect(File).to exist(log_filepath)
    end
  end
end