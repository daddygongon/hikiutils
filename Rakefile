require "bundler/gem_tasks"
require 'yard'
require "rake/testtask"

#task :default => :test
task :default do
  system 'rake -T'
end


desc "make documents by yard"
task :yard do
  system "hiki2md docs/readme.hiki > docs/README.en.md"
  system "hiki2md docs/readme.ja.hiki > docs/README.ja.md"
  YARD::Rake::YardocTask.new
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

#task :default => :spec
