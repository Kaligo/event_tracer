# frozen_string_literal: true

require_relative 'client'

begin
  require 'sidekiq'
  require 'aws-sdk-dynamodb'
rescue LoadError => e
  puts "Please add the missing gem into your app Gemfile: #{e.message}"
  raise
end

module EventTracer
  module DynamoDB
    class Worker
      include ::Sidekiq::Worker

      sidekiq_options retry: 1, queue: 'low'

      # See https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/DynamoDB/Client.html#batch_write_item-instance_method
      MAX_DYNAMO_DB_ITEM_PER_REQUEST = 25

      def initialize(client = nil)
        @config = EventTracer::Config.config
        @client = client || @config.dynamo_db_client || Client.call
      end

      def perform(items)
        wrap(items).each_slice(MAX_DYNAMO_DB_ITEM_PER_REQUEST) do |batch|
          data = batch.map do |item|
            { put_request: { item: clean_empty_values(item) } }
          end

          client.batch_write_item(
            request_items: { config.dynamo_db_table_name => data }
          )

        rescue Aws::DynamoDB::Errors::ServiceError => e
          EventTracer.error(
            loggers: %i(base),
            action: 'DynamoDBWorker',
            app: EventTracer::Config.config.app_name,
            error: e.class.name,
            message: e.message
          )
        end
      end

      private

        attr_reader :client, :config

        def wrap(items)
          # NOTE: This allows us to handle either buffered or unbuffered payloads
          if items.is_a?(Hash)
            [items]
          else
            Array(items)
          end
        end

        # dynamo can't serialise empty strings/ non-zero numerics
        def clean_empty_values(data)
          data.delete_if do |_key, value|
            case value
            when Hash
              clean_empty_values(value)
              false
            when String then value.empty?
            else false
            end
          end
        end

    end
  end
end
