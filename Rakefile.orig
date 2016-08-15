require "bundler/gem_tasks"
require 'yard'
require "rake/testtask"
p base_path = File.expand_path('..', __FILE__)
p basename = File.basename(base_path)

#task :default => :test
task :default do
  system 'rake -T'
end


desc "make documents by yard"
task :yard do
  hiki2md_all(basename)
  YARD::Rake::YardocTask.new
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

#task :default => :spec

def hiki2md_all(basename)
  files = Dir.entries('docs')
  files.each{|file|
    name=file.split('.')
    if name[1]=='hiki' then
      p command="hiki2md docs/#{name[0]}.hiki > #{basename}.wiki/#{name[0]}.md"
      system command
    end
  }
  system "cp #{basename}.wiki/README_ja.md README.md"
  system "cp #{basename}.wiki/README_ja.md #{basename}.wiki/Home.md"
  system "cp docs/*.gif #{basename}.wiki"
  system "cp docs/*.gif doc"
  system "cp docs/*.png #{basename}.wiki"
  system "cp docs/*.png doc"
end
