# EventTracer

[![Build Status](https://travis-ci.org/melvrickgoh/event_tracer.svg?branch=master)](https://travis-ci.org/melvrickgoh/event_tracer)

EventTracer is a thin wrapper to aggregate multiple logging services as a single component with a common interface for utilising the different underlying services.

This gem currently supports only:

1. Base logger (payload in JSON format): Can be initialised around the default loggers like those of Rails or Hanami
2. Appsignal: Empty wrapper around the custom metric distributions
    1. increment_counter
    2. add_distribution_value
    3. set_gauge
3. Datadog:  Empty wrapper around the custom metric distributions
    1. count
    2. distribution
    3. set
    4. gauge
    5. histogram
4. DynamoDB

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
EventTracer.register :dynamo_db, dynamo_db_logger
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

The base logger only with the following format using a `message`,
`action` and all remaining arguments are rendered in a JSON payload

```ruby
# Sample usage
EventTracer.info action: 'Action', message: 'Message', other_args: 'data'
=> "[Action] message {\"other_args\":\"data\"}"
```

**2. Metrics**

EventTracer allows sending metrics together with your log. Currently two
monitoring services are supported: AppSignal and DataDog.

All metrics are sent in `metrics` fields, for example:

```ruby
EventTracer.info(
  action: 'Action',
  message: 'There is an action',
  metrics: {
    metric_1: { type: :counter, value: 12 },
    metric_2: { type: :gauce, value: 1 },
    metric_3: { type: :distribution, value: 10 }
  }
)
```

Extra data in the payload can also be filtered to create tags for each metric:

```ruby
EventTracer.register :appsignal, AppsignalLogger.new(Appsignal, allowed_tags: [:extra_data])
```

Currently, tags apply for all metrics, we don't have support individual tagging yet.


### Appsignal integration

Appsignal >= 2.5 is currently supported for the following metric functions:

| AppSignal function     | EventTracer key |
--------------------------------------------
| increment_counter      | counter         |
| add_distribution_value | distribution    |
| set_gauge              | gauce           |

We can also add [tags](https://docs.appsignal.com/metrics/custom.html#metric-tags) for metric:

```ruby
EventTracer.info(
  action: 'Action',
  message: 'Message',
  metrics: [:counter_1],
  region: 'eu'
)
# This calls .increment_counter on Appsignal once with additional tag
# counter_1, 1, region: 'eu'
```

### DataDog integration

Datadog via dogstatsd-ruby (version >= 4.8) is currently supported for the following metric functions:

| DataDog function     | EventTracer key |
--------------------------------------------
| increment              | counter         |
| distribution           | distribution    |
| gauge                  | gauge           |
| set                    | set             |
| histogram              | histogram       |


```ruby
EventTracer.info action: 'Action', message: 'Message',
  metrics: {
    counter_1: { type: :counter, value: 1 },
    counter_2: { type: :counter, value: 2 }
  }
# This calls .count on Datadog twice with the 2 sets of arguments
#  counter_1, 1
#  counter_2, 2
```


### DynamoDB integration

**Prerequisites:**
- Sidekiq
- AWS DynamoDB SDK

Before using this logger, define the app name that will be sent with each log to DynamoDB:
```ruby
EventTracer::APP_NAME = 'guardhouse'.freeze
```

You will also need to define a private method `prepare_payload` in `EventTracer::DynamoDBLogger`

```ruby
module EventTracer
  class DynamoDBLogger

    private

      def prepare_payload(log_type, action:, message:, args:)
        ...

        args.merge(
          event: event,
          timestamp: Time.now.utc.iso8601(6),
          action: action,
          message: message,
          log_type: log_type,
          app: 'mission_control'
        )
      end

  end
end
```

Alternatively, you can choose to override the `save_message` method:

```ruby
module EventTracer
  class DynamoDBLogger

    private

      def save_message(log_type, action:, message:, **args)
        ...

        payload = args.merge(
          event: event,
          timestamp: Time.now.utc.iso8601(6),
          action: action,
          message: message,
          log_type: log_type,
          app: 'mission_control'
        )

        DynamoDBLogWorker.perform_async(payload)
        LogResult.new(true)
      end

  end
end
```


**Buffer for network/IO optimization (optional)**

For this logger, a thread-safe buffer has been implemented to allow batch sending of logs. To utilise the buffer, define a buffer with an optional keyword argument `buffer_size`, as such:
```ruby
buffer = EventTracer::Buffer.new(
  buffer_size: ENV.fetch('EVENT_TRACER_DEFAULT_BUFFER_SIZE', EventTracer::Buffer::DEFAULT_BUFFER_SIZE).to_i
)
EventTracer.register :dynamodb, EventTracer::DynamoDBLogger.new(buffer)
```

If you prefer not to use the buffer, simply initialize without an argument:
```ruby
EventTracer.register :dynamodb, EventTracer::DynamoDBLogger.new
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

### Summary

In all the generated interface for `EventTracer` logging could look something like this

```ruby
EventTracer.info(
  loggers: %(base appsignal custom_logging_service datadog),
  action: 'NewTransaction',
  message: "New transaction created by API",
  metrics: {
    counter_1: { type: :counter, value: 1 },
    distribution_2: { type: :distribution, value: 10 }
  },
  region: 'eu',
  tenant: 'SomeTenant'
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/melvrickgoh/event_tracer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
