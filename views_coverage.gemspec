Gem::Specification.new do |s|
  s.name        = 'views_coverage'
  s.version     = '0.0.2'
  s.summary     = 'Minitest plugin providing test coverage for views (which templates and partials were and werent generated during tests).'
  s.authors     = ['mmacku']
  s.email       = 'macku@jchsoft.cz'
  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files    = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  s.homepage    = 'https://github.com/jchsoft/views_coverage'
  s.license     = 'MIT'
  s.add_dependency 'activesupport'
end
