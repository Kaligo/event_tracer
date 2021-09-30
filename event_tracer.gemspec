lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'event_tracer/version'

Gem::Specification.new do |spec|
  spec.name          = 'event_tracer'
  spec.version       = EventTracer::VERSION
  spec.authors       = ['melvrickgoh']
  spec.email         = ['melvrickgoh@hotmail.com']

  spec.summary       = 'Thin wrapper for formatted logging/ metric services to be used as a single service'
  spec.description   = 'Thin wrapper for formatted logging/ metric services to be used as a single service. External service(s) supported: Appsignal, Datadog, DynamoDB'
  spec.homepage      = 'https://github.com/melvrickgoh/event_tracer'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = %w[lib/event_tracer lib]

  spec.add_runtime_dependency 'concurrent-ruby'
  spec.add_runtime_dependency 'dry-configurable'

  spec.add_development_dependency "bundler", ">= 2.1.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "timecop"
end
