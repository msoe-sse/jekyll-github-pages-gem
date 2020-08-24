# frozen_string_literal: true

require 'rake/testtask'
require 'rdoc/task'

task default: 'test'

Rake::TestTask.new do |t|
  t.test_files = FileList['tests/**/*_test.rb']
end

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files.include('lib/**/*.rb')
end
