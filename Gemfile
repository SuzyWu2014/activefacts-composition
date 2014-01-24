#source 'https://rubygems.org'
source 'http://rubygems.railscamp.org'

gem 'rake', '~>10.0', :group => [:development, :test]
gem 'activefacts-api', '~> 0.9', '> 0.9.8'

group :development do
  gem 'ruby-debug', '~> 0.10', :platforms => [:mri_18]
  gem 'debugger', '~> 1.6', :platforms => [:mri_19, :mri_20]
  gem 'pry', '~> 0.9', :platforms => [:jruby, :rbx]

  gem 'rspec', '~> 2.3', '~> 2.3.0'
  gem 'bundler', '~> 1.0', '~> 1.0.0'
  gem 'jeweler', '~> 1.5', '~> 1.5.2'
  gem 'rdoc', '~> 2.4', '>= 2.4.2'
end

group :test do
  # rcov 1.0.0 is broken for jruby, so 0.9.11 is the only one available.
  gem 'rcov', '~>0.9.11', :platforms => [:jruby, :mri_18], :require => false
  gem 'simplecov', '~>0.6.4', :platforms => :mri_19, :require => false
end
