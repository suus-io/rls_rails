$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "rls_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "rls_rails"
  spec.version     = RLS::VERSION
  spec.authors     = ["Stephan Biastoch"]
  spec.email       = ["biastoch@suus.io"]
  spec.homepage    = "https://www.suus.io"
  spec.summary     = "PostgreSQL Row Level Security for Ruby on Rails"
  spec.description = ""
  spec.license     = "MIT"


  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 5.2.2"

  spec.add_development_dependency "postgresql"
  spec.add_development_dependency "activerecord", "> 3"
  spec.add_development_dependency "rspec"
end
