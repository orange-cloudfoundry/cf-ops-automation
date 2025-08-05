source 'https://rubygems.org'

ruby '3.4.4'
gem 'rhcl', '~> 0.1.0'
gem 'ostruct', '~> 0.6', '>= 0.6.3'

group :development do
  gem 'docker_registry2', '~> 1.18.2' # https://rubygems.org/gems/docker_registry2
  gem 'git', '~>4.0' # https://rubygems.org/gems/git
  gem 'github_changelog_generator', '~> 1.16.4' # https://rubygems.org/gems/github_changelog_generator
  gem 'mdl', '~>0.13.0'
  gem 'rake', '~>13.3'
  gem 'reek', '~> 6.5.0'
  gem 'rubocop', '~> 1.78.0'
  gem 'rubocop-rspec', '~> 3.6'
end

group :test do
  gem 'cucumber'
  gem 'rspec', '~> 3.13.0'
  gem 'rspec-rerun'
  gem 'simplecov', '~> 0.22.0'
  gem 'csv' #required by ./spec/tasks/repackage_boshreleases_fallback/task_spec.rb and ruby 3.4.4
end
