# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'jekyll-github-pages-gem'
  s.version = '1.1.2'
  s.summary = 'A gem that uses the github API to make edits with a jekyll blog'
  s.files = Dir['*', 'lib/**/*']
  s.require_paths = ['lib']
  s.licenses = ['MIT']
  s.authors = ['MSOE SSE Web Team']
  s.add_runtime_dependency('carrierwave', '>= 2.0.0.rc', '< 3.0')
  s.add_runtime_dependency('kramdown', '~> 2.3.0')
  s.add_runtime_dependency('octokit', '~> 4.18')
  s.required_ruby_version = '>= 2.5.1'
end
