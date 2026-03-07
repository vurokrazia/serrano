require_relative "lib/serrano/version"

Gem::Specification.new do |spec|
  spec.name = "serrano-vk"
  spec.version = Serrano::VERSION
  spec.authors = ["Jesus Martinez"]
  spec.email = ["jesus.alberto.vk@gmail.com"]

  spec.summary = "Minimal Rack-based Ruby microframework."
  spec.description = "Serrano provides minimal HTTP routing, dispatch, request and response abstractions for controller-style applications."
  spec.homepage = "https://github.com/vurokrazia/serrano"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.2"

  tracked_files = begin
    `git ls-files`.split("\n").reject(&:empty?)
  rescue StandardError
    []
  end

  tracked_files = Dir["README.md", "LICENSE*", "EXAMPLES.md", "lib/**/*", "bin/*", "examples/**/*"].select do |path|
    File.file?(path)
  end if tracked_files.empty?

  spec.files = tracked_files.select do |path|
    path.start_with?("lib/", "bin/", "examples/") || path == "README.md" || path == "EXAMPLES.md" || path.match?(/\ALICENSE/)
  end
  spec.executables = ["serrano"]
  spec.require_paths = ["lib"]
  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage
  }

  spec.add_dependency "rack", ">= 3.2.0", "< 4.0.0"
  spec.add_dependency "thor"

  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rackup", ">= 2.3.0", "< 3.0.0"
  spec.add_development_dependency "webrick"
end
