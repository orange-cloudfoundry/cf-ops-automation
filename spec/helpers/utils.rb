require 'securerandom'

def fixtures_dir(path = '')
  File.join(File.join(File.dirname(__FILE__), '..', path, 'fixtures'))
end

def new_tmpdir_path
  File.join(File.join(File.dirname(__FILE__), '../..', 'tmp', SecureRandom.uuid))
end
