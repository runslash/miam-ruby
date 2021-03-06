require_relative 'lib/miam/version'

Gem::Specification.new do |spec|
  spec.name          = "miam"
  spec.version       = Miam::VERSION
  spec.authors       = ["Julien D."]
  spec.email         = ["julien@unitylab.io"]

  spec.summary       = %q{MIAM - Managed Identity & Access Management}
  spec.description   = %q{MIAM - Managed Identity & Access Management}
  spec.homepage      = 'https://github.com/runslash/miam'
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = 'https://github.com/runslash/miam'
  spec.metadata["changelog_uri"] = 'https://github.com/runslash/miam'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'puma', '~> 4.3'
  spec.add_dependency 'rack', '~> 2.2'
  spec.add_dependency 'aws-sdk-dynamodb', '~> 1.45'
  spec.add_dependency 'activemodel', '~> 6.0'
  spec.add_dependency 'bcrypt', '~> 3.1'
  spec.add_dependency 'redis', '~> 4.1'
  spec.add_dependency 'concurrent-ruby'

  spec.add_dependency 'pry'
end
