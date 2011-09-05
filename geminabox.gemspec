Gem::Specification.new do |s|
  s.name              = 'geminabox'
  s.version           = '0.3.1'
  s.summary           = 'Really simple rubygem hosting'
  s.description       = 'A sinatra based gem hosting app, with client side gem push style functionality.'
  s.author            = 'Tom Lea'
  s.email             = 'contrib@tomlea.co.uk'
  s.homepage          = 'http://tomlea.co.uk/p/gem-in-a-box'

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w[README.markdown]
  s.rdoc_options      = %w[--main README.markdown]

  s.files             = %w[README.markdown] + Dir['{lib,public,views}/**/*']
  s.require_paths     = ['lib']

  s.add_dependency('sinatra')
  s.add_dependency('builder')
end
