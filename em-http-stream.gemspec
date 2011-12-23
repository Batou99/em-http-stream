# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{em-http-stream}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vladimir Kolesnikov", "Kliment Mamykin"]
  s.date = %q{2011-12-22}
  s.description = %q{Simple Ruby client library for consuming HTTP streaming API. Uses EventMachine for connection handling. JSON format only.}
  s.summary = %q{HTTP streaming API client}
  s.homepage = %q{http://github.com/kmamykin/em-http-stream}
  s.email = %q{kmamyk@gmail.com}

  s.platform                  = Gem::Platform::RUBY
  s.rubygems_version          = %q{1.3.6}
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=

  s.rdoc_options = ["--charset=UTF-8"]
  s.extra_rdoc_files = ["README.markdown"]

  s.add_runtime_dependency('eventmachine', ">= 0.12.8")
  s.add_runtime_dependency('simple_oauth', '~> 0.1.4')
  s.add_runtime_dependency('http_parser.rb', '~> 0.5.1')
  s.add_development_dependency('rspec', "~> 2.5.0")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end

