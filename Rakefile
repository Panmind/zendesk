require 'rake'
require 'rake/rdoctask'

require 'lib/panmind/zendesk'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name             = 'panmind-zendesk'

    gemspec.summary          = 'Zendesk on Rails - Dropbox and Remote Authentication'
    gemspec.description      = 'The plugin implements the HTML generation code for the '   \
                               'Zendesk dropbox and the necessary controller and routing ' \
                               'code to implement remote authentication'

    gemspec.authors          = ['Marcello Barnaba']
    gemspec.email            = 'vjt@openssl.it'
    gemspec.homepage         = 'http://github.com/Panmind/zendesk'

    gemspec.files            = %w( README.md Rakefile rails/init.rb ) + Dir['lib/**/*']
    gemspec.extra_rdoc_files = %w( README.md )
    gemspec.has_rdoc         = true

    gemspec.version          = Panmind::Zendesk::Version
    gemspec.date             = '2010-11-17'

    gemspec.require_path     = 'lib'

    gemspec.add_dependency('rails', '~> 2.3.8')
  end
rescue LoadError
  puts 'Jeweler not available. Install it with: gem install jeweler'
end

desc 'Generate the rdoc'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_files.add %w( README.md lib/**/*.rb )

  rdoc.main  = 'README.md'
  rdoc.title = 'Zendesk on Rails - Dropbox and Remote Authentication'
end

desc 'Will someone help write tests?'
task :default do
  puts
  puts 'Can you help in writing tests? Please do :-)'
  puts
end
