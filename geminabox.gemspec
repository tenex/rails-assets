require File.expand_path('../lib/geminabox/version', __FILE__)

Gem::Specification.new do |s|
  s.name              = 'geminabox'
  s.version           = GeminaboxVersion
  s.summary           = 'Really simple rubygem hosting'
  s.description       = 'A sinatra based gem hosting app, with client side gem push style functionality.'
  s.authors           = ['Tom Lea', 'Jack Foy']
  s.email             = ['contrib@tomlea.co.uk', 'jack@foys.net']
  s.homepage          = 'http://tomlea.co.uk/p/gem-in-a-box'

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w[README.md]
  s.rdoc_options      = %w[--main README.md]

  s.files             = %w[README.md] + Dir['{lib,public,views}/**/*']
  s.require_paths     = ['lib']

  s.add_dependency('sinatra')
  s.add_dependency('builder')
  s.add_dependency('slim')
  s.add_dependency('thin')
  s.add_dependency('httpclient', [">= 2.2.7"])
  s.add_development_dependency('rake')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('minitest')
  s.add_development_dependency('capybara')
  s.add_development_dependency('capybara-mechanize')
  s.add_development_dependency('pry')
end
