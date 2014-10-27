source 'https://rubygems.org'

gem 'rake', '~>10.0', :group => [:development, :test]
gem 'activefacts-api', '~> 1.0'

group :development do
  gem 'ruby-debug', '~> 0.10', :platforms => [:mri_18]
  gem 'debugger', '~> 1.6', :platforms => [:mri_19, :mri_20]
  gem 'pry', '~> 0.9', :platforms => [:jruby, :rbx]

  gem 'rspec'
  gem 'bundler'
  gem 'jeweler'
  gem 'rdoc'
end

group :test do
  # rcov 1.0.0 is broken for jruby, so 0.9.11 is the only one available.
  gem 'rcov', '~>0.9.11', :platforms => [:jruby, :mri_18], :require => false
  gem 'simplecov', '~>0.6.4', :platforms => :mri_19, :require => false
end
