version = File
  .read(File.join(__dir__, "lib/serrano/version.rb"))
  .match(/VERSION = ["']([^"']+)["']/)[1]

Gem::Specification.new do |spec|
  spec.name = "serrano"
  spec.version = version
  spec.authors = ["Serrano contributors"]
  spec.email = ["opensource@example.com"]

  spec.summary = "Minimal Rack-based Ruby microframework."
  spec.description = "Serrano provides minimal HTTP routing, dispatch, request and response abstractions for controller-style applications."
  spec.homepage = "https://github.com/vurokrazia/serrano"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["{bin,lib,examples}/**/*", "README.md", "LICENSE*"].reject do |path|
    path.include?(".gemspec") || File.directory?(path)
  end
  spec.executables = ["serrano"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 3.2.0", "< 4.0.0"
  spec.add_dependency "rackup", ">= 2.3.0", "< 3.0.0"

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "thor"
  spec.add_development_dependency "sequel"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "webrick"
  spec.add_development_dependency "minitest"
end
