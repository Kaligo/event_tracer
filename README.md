# EventTracer

[![Build Status](https://travis-ci.org/melvrickgoh/event_tracer.svg?branch=master)](https://travis-ci.org/melvrickgoh/event_tracer)

EventTracer is a thin wrapper to aggregate multiple logging services as a single component with a common interface for utilising the different underlying services.

This gem currently supports only: 

1. Base logger (payload in JSON format): Can be initialised around the default loggers like thos of Rails or Hanami
2. Appsignal: Empty wrapper around the custom metric distributions
    1. increment_counter
    2. add_distribution_value
    3. set_gauge
3. Datadog:  Empty wrapper around the custom metric distributions
    1. increment
    2. distribution
    3. set
    4. gauge
    5. histogram    

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
base_logger = EventTracer::BaseLogger.new(your_logger)
appsignal_logger = EventTracer::AppsignalLogger.new(Appsignal)
```

**2. Registering the wrapped loggers**

Each initialised logger is then registered to `EventTracer`. 

```ruby
EventTracer.register :base, base_logger
EventTracer.register :appsignal, appsignal_logger
EventTracer.register :datadog, datadog_logger
```

As this is a registry, you can set it up with your own implemented wrapper as long as it responds to the following `LOG_TYPES` methods: `info, warn, error`

### Service Interfaces

**Top-level Controls**

You can control the loggers to use when sending the event by using the top-level `loggers` key to specify the logger service(s) to apply to. 

Key | Key type | Required | Values
----|----------|----------|--------
loggers | Array[Symbol] | N | Array of symbolised logger codes registered for use
action | String | Y | Action label to prepend log messages with
message | String | Y | This is the basic message to be used for all services

This accepts an array of the loggers' codes which will be used to select the loggers to send messages for. Invalid/ empty values will be treated as blank and all loggers will be invoked in such a scenario.

**1. Base Logger**

The base logger only with the following format using a `message`, `action` and all remaining arguments are rendered in a JSON payload

```ruby
# Sample usage
EventTracer.info action: 'Action', message: 'Message', other_args: 'data'
=> "[Action] message {\"other_args\":\"data\"}"
```

**2. Appsignal**

Appsignal 2.5.1 is currently supported for the following metric functions available for the EventTracer's log methods

- increment_counter
- add_distribution_value
- set_gauge

All other functions are exposed transparently to the underlying Appsignal class

The interface for using the Appsignal wrapper is:

Key | Secondary key | Secondary key type | Values
--------------|-------------|------------------|-------
appsignal | increment_counter | Hash | Hash of key-value pairs featuring the metric name and the counter value to send
| | add_distribution_value | Hash | Hash of key-value pairs featuring the metric name and the distribution value to send
| | set_gauge | Hash | Hash of key-value pairs featuring the metric name and the gauge value to send

```ruby
# Sample usage
EventTracer.info action: 'Action', message: 'Message', appsignal: { increment_counter: { counter_1: 1, counter_2: 2 } }
# This calls .increment_counter on Appsignal twice with the 2 sets of arguments
#  counter_1, 1
#  counter_2, 2
```

**3. Datadog**

Datadog via dogstatsd-ruby (4.8.1) is currently supported for the following metric functions available for the EventTracer's log methods

- increment
- distribution
- set
- gauge
- histogram

All other functions are exposed transparently to the underlying Appsignal class

The interface for using the Appsignal wrapper is:

Key | Secondary key | Secondary key type | Values
--------------|-------------|------------------|-------
datadog | increment | Hash | Hash of key-value pairs featuring the metric name and the counter value to send
| | distribution | Hash | Hash of key-value pairs featuring the metric name and the distribution value to send
| | set | Hash | Hash of key-value pairs featuring the metric name and the set value to send
| | gauge | Hash | Hash of key-value pairs featuring the metric name and the gauge value to send
| | histogram | Hash | Hash of key-value pairs featuring the metric name and the histogram value to send

```ruby
# Sample usage
EventTracer.info action: 'Action', message: 'Message', datadog: { increment: { counter_1: 1, counter_2: { value: 2, tags: ['foo']} } }
# This calls .increment_counter on Datadog twice with the 2 sets of arguments
#  counter_1, 1
#  counter_2, 2
```

**Summary**

In all the generated interface for `EventTracer` logging could look something like this

```ruby
EventTracer.info(
  loggers: %(base appsignal custom_logging_service datadog),
  action: 'NewTransaction',
  message: "New transaction created by API",
  appsignal: {
    add_distribution_value: {
      "distribution_metric_1" => 1000,
      "distribution_metric_2" => 2000
    }
  },
  datadog: {
    distribution: {
      "distribution_metric_1" => 1000,
      "distribution_metric_2" => { value: 2000, tags: ['eu'] }
    }
  }
)
```

### Results

Logging is a side task that should never fail. So we capture any exceptions so that any issue does not impact the flow of your application.

The `EventTracer` returns a `EventTracer::Result` object that logs the success/ failure of the outcome of your execution in case you'd like to investigate why your services ain't working.

Each log result is mapped to the code of the activated logger

**Sample**

```ruby
result = EventTracer.info action: '123', message: '' # <EventTracer::Result @records={:base=>#<struct EventTracer::LogResult :success?=true, error=nil>}>
result.records[:base].success? => true
result.records[:base].error => nil
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/melvrickgoh/event_tracer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
