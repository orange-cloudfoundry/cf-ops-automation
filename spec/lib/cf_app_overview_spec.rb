require 'rspec'
require 'yaml'
require 'fileutils'
require_relative '../../lib/cf_app_overview'

describe CfAppOverview do

  describe 'enable-cf-app.yml format validation' do
    it 'can have multiple applications'

    it 'root elem name is cf-app'
  end

  describe '#overview' do
    it 'get all enable-cf-app.yml into a hash'

    it 'add a base-dir for each file found'

    it 'application name are uniq across all enable-cf-app.yml'
  end

end