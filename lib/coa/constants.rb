module Coa
  # This module describes constants useful for COA
  module Constants
    PROJECT_ROOT_DIR = Pathname.new(File.join(File.dirname(__FILE__), "../..")).realdirpath
    REFERENCE_DATASET_PATH = Pathname.new(File.join("#{PROJECT_ROOT_DIR}/docs/reference_dataset")).realdirpath
  end
end
