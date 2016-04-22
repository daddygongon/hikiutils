# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hikiutils/version'

Gem::Specification.new do |spec|
  spec.name          = "hikiutils"
  spec.version       = HikiUtils::VERSION
  spec.authors       = ["Shigeto R. Nishitani"]
  spec.email         = ["shigeto_nishitani@me.com"]

  spec.summary       = %q{helper of hiki editing.}
  spec.description   = %q{.}
  spec.homepage      = "http://github.org/daddygongon/hikiutils."
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
#  if spec.respond_to?(:metadata)
#    spec.metadata['allowed_push_host'] = 'http://rubygems.org'
#  else
#    raise "use 'gem inabox -o pkg/hogehoge.gem' for releasing on the non-public server."
#  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "hiki2md"
  spec.add_runtime_dependency "systemu"
  spec.add_runtime_dependency "hikidoc","~>0.1.0"

end
