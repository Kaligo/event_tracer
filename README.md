# EventTracer

EventTracer is a thin wrapper to aggregate multiple logging services as a single component with a common interface for utilising the different underlying services.

This gem currently supports only: 

1. Base logger (payload in JSON format): Can be initialised around the default loggers like thos of Rails or Hanami
2. Appsignal: Empty wrapper around the custom metric distributions
  1. increment_counter
  2. add_distribution_value
  3. set_gauge

No dependencies are declared for this as the  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'event_tracer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install event_tracer

## Usage

There're 2 sections to using the gem

**1. Initialising the individual loggers**

Each individual logger should receive the relevant logging services to wrap onto.

```ruby
base_logger = EventTracer::Logger.new(your_logger)
appsignal_logger = EventTracer::AppsignalLogger.new(Appsignal)
```

**2. Registering the wrapped loggers**

Each initialised logger is then registered to `EventTracer`. 

```ruby
EventTracer.register :base, base_logger
EventTracer.register :appsignal, appsignal_logger
```

As this is a registry, you can set it up with your own implemented wrapper as long as it responds to the following `LOG_TYPES` methods: `info, warn, error`

### Supported Services

**Appsignal**: Appsignal 2.5.1 is currently supported for the following metric functions available for the EventTracer's log methods

- increment_counter
- add_distribution_value
- set_gauge

All other functions are exposed transparently to the underlying Appsignal class

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/melvrickgoh/event_tracer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
